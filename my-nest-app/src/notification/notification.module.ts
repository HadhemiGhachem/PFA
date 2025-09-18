import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { NotificationsController } from './notification.controller';
import { NotificationsService } from './notification.service';
import { Notification, NotificationSchema } from './schemas/notification.schema';
import { JwtModule } from '@nestjs/jwt';
import { NotificationGateway } from './notification.gateway';


@Module({
  imports: [
    MongooseModule.forFeature([{ name: Notification.name, schema: NotificationSchema }]),
    JwtModule.register({
      secret: 'your_jwt_secret', // Remplacez par le secret JWT de votre module d'authentification
      signOptions: { expiresIn: '1h' },
    }),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService , NotificationGateway],
  exports: [NotificationsService , NotificationGateway], 
})
export class NotificationsModule {}