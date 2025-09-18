// src/cars/cars.controller.ts
import { Controller, Get, Post, Delete, Body, Param, NotFoundException, UploadedFile, UseInterceptors, UseGuards, Request, UnauthorizedException } from '@nestjs/common';
import { CarsService } from './cars.service';
import { extname } from 'path';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { CreateCarDto, CarDto } from './dto/create-car.dto';
import { NotificationsService } from 'src/notification/notification.service';
import { NotificationGateway } from 'src/notification/notification.gateway';

interface JwtUser {
  userId: string;
  email: string;
}

@Controller('cars')
export class CarsController {
  constructor(
    private readonly carsService: CarsService,
    private readonly notificationsService: NotificationsService,
    private readonly notificationGateway: NotificationGateway, // Ajouter le gateway
  ) {}

  @Get('getAllCars')
  async findAll(): Promise<CarDto[]> {
    return this.carsService.findAll();
  }

  @Get('getCarById/:id')
  async findOne(@Param('id') id: string): Promise<CarDto> {
    const car = await this.carsService.findOne(id);
    if (!car) throw new NotFoundException(`Car with ID ${id} not found`);
    return car;
  }

  @Post('createCar')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: './Uploads',
        filename: (req, file, callback) => {
          const randomName = Array(32)
            .fill(null)
            .map(() => Math.round(Math.random() * 16).toString(16))
            .join('');
          callback(null, `${randomName}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  async create(
    @Body() createCarDto: CreateCarDto,
    @UploadedFile() file: Express.Multer.File,
    @Request() req: { user?: JwtUser },
  ): Promise<CarDto> {
    console.log('[DEBUG] User object from token:', req.user);
    if (!req.user) {
      throw new UnauthorizedException('User not authenticated');
    }
    const userId = req.user.userId;
    if (!userId) {
      throw new UnauthorizedException('User ID not found in token');
    }
    if (file) {
      createCarDto.image = `http://10.0.2.2:6006/uploads/${file.filename}`;
    }
    const car = await this.carsService.create(createCarDto, userId);
    const notification = await this.notificationsService.createNotification(
            'New Car Added',
      `You added a ${car.brand} ${car.carModel}`,
      userId,
      car.id,
      'car_added',
    );
    // Émettre la notification via WebSocket
    await this.notificationGateway.sendNotificationToUser(userId, notification);
    return car;
  }

  @Delete('deleteCar/:id')
  async remove(@Param('id') id: string): Promise<{ message: string }> {
    const result = await this.carsService.remove(id);
    if (!result) throw new NotFoundException(`Car with ID ${id} not found`);
    return { message: `Car with ID ${id} deleted` };
  }

  @Post('uploadImage')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: './Uploads',
        filename: (req, file, callback) => {
          const randomName = Array(32)
            .fill(null)
            .map(() => Math.round(Math.random() * 16).toString(16))
            .join('');
          callback(null, `${randomName}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  async uploadImage(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new Error('No file uploaded');
    }
    const url = `http://10.0.2.2:6006/uploads/${file.filename}`;
    return { url };
  }
}