import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CarsModule } from './cars/cars.module';
import { AuctionsModule } from './auctions/auctions.module';
import { BidModule } from './bid/bid.module';
import { MulterModule } from '@nestjs/platform-express';
import { NotificationsModule } from './notification/notification.module';
import { ScheduleModule } from '@nestjs/schedule';


@Module({
  imports: [
    
    MulterModule.register({
      dest: './uploads', // Dossier où les images seront stockées
    }),
    ConfigModule.forRoot({
      envFilePath: '.env',
      isGlobal: true,
    }),
    ScheduleModule.forRoot(),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (config: ConfigService) => {
        const uri = config.get<string>('DATABASE_URL');
        console.log('🔗 URI MongoDB utilisée :', uri);
        return { uri, dbName: 'my-nest-app' };
      },
      inject: [ConfigService],
    }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '1h' },
      }),
      inject: [ConfigService],
      global: true,
    }),
    AuthModule,
    UsersModule,
    CarsModule,
    AuctionsModule,
    BidModule,
    NotificationsModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}