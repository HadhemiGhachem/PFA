// src/notification/dto/create-notification.dto.ts
import { IsString } from 'class-validator';

export class CreateNotificationDto {
  @IsString()
  title: string;

  @IsString()
  message: string;

  @IsString()
  userId: string;

  @IsString()
  carId: string;

  @IsString()
  type: string;
}

export class NotificationDto {
  id: string;
  title: string;
  message: string;
  userId: string;
  carId: string;
  type: string;
  createdAt: Date;
  isRead: boolean; 
}