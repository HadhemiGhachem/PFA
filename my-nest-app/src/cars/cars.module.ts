// src/cars/cars.module.ts
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CarsController } from './cars.controller';
import { CarsService } from './cars.service';
import { Car, CarSchema } from './schemas/car.schema';
import { NotificationsModule } from 'src/notification/notification.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Car.name, schema: CarSchema }]),
    NotificationsModule
  ],
  controllers: [CarsController],
  providers: [CarsService ],
})
export class CarsModule {}