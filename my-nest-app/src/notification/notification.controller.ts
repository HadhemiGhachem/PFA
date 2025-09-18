// src/notification/notification.controller.ts
import { Controller, Get, Patch, Delete, Param, Request, UseGuards, UnauthorizedException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notification.service';
import { NotificationDto } from './dto/notification.dto';

interface JwtUser {
  userId: string;
  email: string;
}

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get('getUserNotifications')
  @UseGuards(JwtAuthGuard)
  async getUserNotifications(@Request() req: { user?: JwtUser }): Promise<NotificationDto[]> {
    console.log('[DEBUG] User object from token:', req.user);
    if (!req.user) {
      throw new UnauthorizedException('User not authenticated');
    }
    const userId = req.user.userId;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    return this.notificationsService.getUserNotifications(userId);
  }

  @Patch(':id/read')
  @UseGuards(JwtAuthGuard)
  async markAsRead(@Param('id') id: string): Promise<NotificationDto> {
    return this.notificationsService.markAsRead(id);
  }

  @Patch('markAllAsRead')
  @UseGuards(JwtAuthGuard)
  async markAllAsRead(@Request() req: { user?: JwtUser }): Promise<{ message: string }> {
    console.log('[DEBUG] User object from token:', req.user);
    if (!req.user) {
      throw new UnauthorizedException('User not authenticated');
    }
    const userId = req.user.userId;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    await this.notificationsService.markAllAsReadForUser(userId);
    return { message: 'All notifications marked as read' };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async deleteNotification(@Param('id') id: string): Promise<{ message: string }> {
    await this.notificationsService.deleteNotification(id);
    return { message: 'Notification deleted successfully' };
  }

  @Delete('all')
  @UseGuards(JwtAuthGuard)
  async deleteAllNotifications(@Request() req: { user?: JwtUser }): Promise<{ message: string }> {
    console.log('[DEBUG] User object from token:', req.user);
    if (!req.user) {
      throw new UnauthorizedException('User not authenticated');
    }
    const userId = req.user.userId;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    await this.notificationsService.deleteAllNotificationsForUser(userId);
    return { message: 'All notifications deleted successfully' };
  }
}