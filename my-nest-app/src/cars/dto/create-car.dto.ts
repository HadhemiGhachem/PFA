// src/cars/dto/create-car.dto.ts
import { IsString, IsNumber, IsBoolean, IsOptional, IsObject } from 'class-validator';

export class CreateCarDto {
  @IsString()
  licensePlate: string;

  @IsString()
  chassisNumber: string;

  @IsString()
  brand: string;

  @IsString()
  carModel: string;

  @IsNumber()
  year: number;

  @IsNumber()
  cylinders: number;

  @IsString()
  currentCard: string;

  @IsNumber()
  power: number;

  @IsNumber()
  speed: number;

  @IsString()
  lights: string;

  @IsString()
  assistance: string;

  @IsNumber()
  seats: number;

  @IsBoolean()
  airConditioning: boolean;

  @IsBoolean()
  screen: boolean;

  @IsString()
  image: string;

  @IsOptional()
  @IsBoolean()
  hasSunroof?: boolean;

  @IsOptional()
  @IsObject()
  seatCondition?: {
    clean: boolean;
    stained: boolean;
    torn: boolean;
    heated: boolean;
    electric: boolean;
  };

  @IsOptional()
  @IsNumber()
  auctionDuration?: number;

  @IsOptional()
  @IsString()
  auctionStartDate?: string;

  @IsOptional()
  @IsString()
  auctionEndDate?: string;

  @IsOptional()
  @IsNumber()
  initialPrice?: number;

  @IsString()
  userId: string;
}

export class CarDto {
  id: string;
  licensePlate: string;
  chassisNumber: string;
  brand: string;
  carModel: string;
  year: number;
  cylinders: number;
  currentCard: string;
  power: number;
  speed: number;
  lights: string;
  assistance: string;
  seats: number;
  airConditioning: boolean;
  screen: boolean;
  image: string;
  hasSunroof?: boolean;
  seatCondition?: {
    clean: boolean;
    stained: boolean;
    torn: boolean;
    heated: boolean;
    electric: boolean;
  };
  auctionDuration?: number;
  auctionStartDate?: string;
  auctionEndDate?: string;
  initialPrice?: number;
  userId: string;
}