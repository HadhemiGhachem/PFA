// src/cars/cars.service.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Car, CarDocument } from './schemas/car.schema';
import { CreateCarDto, CarDto } from './dto/create-car.dto';

@Injectable()
export class CarsService {
  constructor(@InjectModel(Car.name) private carModel: Model<CarDocument>) {}

  async findAll(): Promise<CarDto[]> {
    const cars: CarDocument[] = await this.carModel.find().exec();
    return cars.map((car: CarDocument) => car.toObject() as CarDto);
  }

  async findOne(id: string): Promise<CarDto | null> {
    const car: CarDocument | null = await this.carModel.findById(id).exec();
    if (!car) return null;
    return car.toObject() as CarDto;
  }

  async create(createCarDto: CreateCarDto, userId: string): Promise<CarDto> {
    try {
      const createdCar = new this.carModel({
        ...createCarDto,
        userId: new Types.ObjectId(userId),
      });
      const savedCar: CarDocument = await createdCar.save();
      return savedCar.toObject() as CarDto;
    } catch (error) {
      throw new Error(`Failed to create car: ${error.message}`);
    }
  }

  async update(id: string, car: Partial<CarDto>): Promise<CarDto | null> {
    const updatedCar: CarDocument | null = await this.carModel
      .findByIdAndUpdate(id, car, { new: true })
      .exec();
    if (!updatedCar) return null;
    return updatedCar.toObject() as CarDto;
  }

  async remove(id: string): Promise<boolean> {
    const result: CarDocument | null = await this.carModel.findByIdAndDelete(id).exec();
    return !!result;
  }
}