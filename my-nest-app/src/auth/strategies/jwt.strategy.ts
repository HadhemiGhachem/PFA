import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    const secret = configService.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables');
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: { userId: string; email?: string }) {
    console.log('[DEBUG] JWT Payload:', payload);
    if (!payload.userId) {
      console.log('❌ Payload invalide, userId manquant');
      throw new UnauthorizedException('Payload JWT invalide');
    }
    return { userId: payload.userId, email: payload.email || '' }; // Return userId, not id
  }
}