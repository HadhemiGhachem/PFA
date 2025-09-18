import { IsString, IsNumber, Min } from 'class-validator';

export class CreateBidDto {
  @IsString()
  auctionId: string;

  @IsString()
  userId: string;

  @IsNumber()
  @Min(0)
  amount: number;
  
  bidAmount: number;
}