import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Notification, NotificationDocument } from './schemas/notification.schema';
import { NotificationDto } from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name) private notificationModel: Model<NotificationDocument>,
  ) {}

  async createNotification(
    title: string,
    message: string,
    userId: string,
    carId?: string,
    type: string = 'car_added',
  ): Promise<NotificationDto> {
    const notification = new this.notificationModel({
      title,
      message,
      userId,
      carId: carId ? new Types.ObjectId(carId) : undefined,
      type,
    });
    const savedNotification = await notification.save();
    return {
      id: savedNotification._id.toString(),
      title: savedNotification.title,
      message: savedNotification.message,
      userId: savedNotification.userId.toString(),
      carId: savedNotification.carId?.toString(),
      type: savedNotification.type,
      isRead: savedNotification.isRead,
      createdAt: savedNotification.createdAt,
      updatedAt: savedNotification.updatedAt,
    };
  }

  async getUserNotifications(userId: string): Promise<NotificationDto[]> {
    const notifications = await this.notificationModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .exec();
    return notifications.map(notification => ({
      id: notification._id.toString(),
      title: notification.title,
      message: notification.message,
      userId: notification.userId.toString(),
      carId: notification.carId?.toString(),
      type: notification.type,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
    }));
  }

  async markAsRead(notificationId: string): Promise<NotificationDto> {
    const notification = await this.notificationModel
      .findByIdAndUpdate(notificationId, { isRead: true }, { new: true })
      .exec();
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    return {
      id: notification._id.toString(),
      title: notification.title,
      message: notification.message,
      userId: notification.userId.toString(),
      carId: notification.carId?.toString(),
      type: notification.type,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
    };
  }

  async markAllAsReadForUser(userId: string): Promise<void> {
    await this.notificationModel
      .updateMany(
        { userId: new Types.ObjectId(userId), isRead: false },
        { isRead: true, updatedAt: new Date() },
      )
      .exec();
  }

  async deleteNotification(notificationId: string): Promise<void> {
    const result = await this.notificationModel.findByIdAndDelete(notificationId).exec();
    if (!result) {
      throw new NotFoundException('Notification not found');
    }
  }

  async deleteAllNotificationsForUser(userId: string): Promise<void> {
    await this.notificationModel.deleteMany({ userId: new Types.ObjectId(userId) }).exec();
  }
}