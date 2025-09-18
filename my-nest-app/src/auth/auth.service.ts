import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { signupDto } from './dtos/signup.dto';
import { LoginDto } from './dtos/login.dto';
import { User } from './schemas/user.schema';
import { RefreshToken } from './schemas/refresh-token.schema';
import { UsersService } from '../users/users.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(RefreshToken.name) private refreshTokenModel: Model<RefreshToken>,
    private jwtService: JwtService,
    private readonly usersService: UsersService,
  ) {}

  async signup(signupData: signupDto): Promise<any> {
    const { email, password, firstname, lastname } = signupData;
    console.log('📥 Données reçues pour l’inscription :', signupData);

    const emailInUse = await this.userModel.findOne({ email });
    if (emailInUse) {
      console.log('❌ Email déjà utilisé :', email);
      throw new BadRequestException('Email already in use');
    }

    const hashedPassword = await bcrypt.hash(password.toString(), 10);
    console.log('🔑 Mot de passe hashé :', hashedPassword);

    try {
      const newUser = new this.userModel({
        firstname,
        lastname,
        email,
        password: hashedPassword,
      });

      const savedUser = await newUser.save();
      console.log('✅ Utilisateur enregistré :', savedUser);

      return {
        message: 'Utilisateur enregistré avec succès',
        user: savedUser,
      };
    } catch (error) {
      console.error('❌ Erreur d’insertion MongoDB :', error);
      throw new BadRequestException('Erreur lors de l’inscription');
    }
  }

  async login(credentials: LoginDto) {
    const { email, password } = credentials;
    console.log('📤 Tentative de connexion avec :', email);

    const user = await this.userModel.findOne({ email });
    if (!user) {
      console.log('❌ Utilisateur introuvable :', email);
      throw new UnauthorizedException('Wrong credentials');
    }

    const passwordMatch = await bcrypt.compare(password.toString(), user.password.toString());
    if (!passwordMatch) {
      console.log('❌ Mot de passe incorrect pour :', email);
      throw new UnauthorizedException('Wrong credentials');
    }

    const tokens = await this.generateUserTokens(String(user._id));
    await this.storeRefreshToken(tokens.refreshToken, String(user._id)); // Stockez le refresh token
    console.log('✅ Connexion réussie, token généré :', tokens.accessToken);

    return {
      user: {
        id: user._id,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
      },
      message: 'Connexion réussie',
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }

  async generateUserTokens(userId: string) {
    const payload = { userId }; // Simplifiez le payload
    const accessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });
    return { accessToken, refreshToken };
  }

  async storeRefreshToken(token: string, userId: string) {
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 7); // Alignez avec expiresIn

    await this.refreshTokenModel.create({ token, userId, expiryDate });
  }

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.usersService.findOneByEmail(email);
    if (user && (await bcrypt.compare(password, user.password))) {
      return {
        id: user._id,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
      };
    }
    return null;
  }
}