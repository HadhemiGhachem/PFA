import { IsString, IsDateString, IsNumber, Min, IsNotEmpty, IsOptional, IsMongoId } from 'class-validator';


export class UpdateAuctionDto {
    @IsDateString()
    @IsOptional()
    startDate?: string;
  
    @IsDateString()
    @IsOptional()
    endDate?: string;
  
    @IsNumber()
    @Min(0)
    @IsOptional()
    startingPrice?: number;
  
    @IsMongoId()
    @IsOptional()
    carId?: string;
  
    @IsString()
    @IsOptional()
    status?: string;
  }