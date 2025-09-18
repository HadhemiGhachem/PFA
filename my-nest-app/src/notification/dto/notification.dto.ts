export class NotificationDto {
    id: string;
    title: string;
    message: string;
    userId: string;
    carId?: string;
    type: string;
    isRead: boolean;
    createdAt: Date;
    updatedAt?: Date;

  }