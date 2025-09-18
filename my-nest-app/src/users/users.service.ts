import { BadRequestException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../auth/schemas/user.schema';
import { UpdateUserDto } from './dtos/update-user.dto';
import { UserProfileDto } from './dtos/user-profile.dto';
import * as bcrypt from 'bcrypt';
import { CreateUserDto } from './dtos/createUser.dto';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async createUser(createUserDto: CreateUserDto): Promise<UserDocument> {
    const { firstname, lastname, email, password } = createUserDto;
    const existingUser = await this.userModel.findOne({ email }).exec();
    if (existingUser) {
      throw new BadRequestException('Cet email est déjà utilisé');
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new this.userModel({
      firstname,
      lastname,
      email,
      password: hashedPassword,
    });
    return user.save();
  }

  async findAll(): Promise<UserDocument[]> {
    return this.userModel.find().exec();
  }

  async findById(userId: string): Promise<UserProfileDto> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }
    return {
      id: user.id,
      firstname: user.firstname,
      lastname: user.lastname,
      email: user.email,
    };
  }

  async findOneById(userId: string): Promise<UserDocument | null> {
    return this.userModel.findById(userId).exec();
  }

  async findOneByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email }).exec();
  }

  async updateProfile(userId: string, updateData: UpdateUserDto): Promise<UserProfileDto> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }

    // Vérifier l'unicité de l'email
    if (updateData.email && updateData.email !== user.email) {
      const existingUser = await this.userModel.findOne({ email: updateData.email }).exec();
      if (existingUser) {
        throw new BadRequestException('Cet email est déjà utilisé');
      }
    }

    // Vérifier et mettre à jour le mot de passe
    if (updateData.oldPassword && updateData.newPassword) {
      const isPasswordValid = await bcrypt.compare(updateData.oldPassword, user.password);
      if (!isPasswordValid) {
        throw new UnauthorizedException('Ancien mot de passe incorrect');
      }
      user.password = await bcrypt.hash(updateData.newPassword, 10);
    } else if (updateData.newPassword && !updateData.oldPassword) {
      throw new BadRequestException('L\'ancien mot de passe est requis pour changer le mot de passe');
    } else if (updateData.oldPassword && !updateData.newPassword) {
      throw new BadRequestException('Nouveau mot de passe requis');
    }

    // Mettre à jour les autres champs
    if (updateData.firstname) user.firstname = updateData.firstname;
    if (updateData.lastname) user.lastname = updateData.lastname;
    if (updateData.email) user.email = updateData.email;

    await user.save();

    return {
      id: user.id,
      firstname: user.firstname,
      lastname: user.lastname,
      email: user.email,
    };
  }

  async deleteUser(userId: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(userId).exec();
    if (!result) {
      throw new NotFoundException(`Utilisateur avec l'ID ${userId} non trouvé`);
    }
  }

  
}