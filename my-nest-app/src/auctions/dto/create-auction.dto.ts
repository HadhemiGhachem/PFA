import { IsString, IsDateString, IsNumber, Min, IsNotEmpty } from 'class-validator';

export class CreateAuctionDto {
  @IsString()
  @IsNotEmpty()
  carId: string;

  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @IsNumber()
  @Min(0)
  @IsNotEmpty()
  startingPrice: number;
}