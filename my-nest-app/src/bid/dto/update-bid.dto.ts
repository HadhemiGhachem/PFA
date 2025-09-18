import { IsString, IsNumber, IsOptional } from 'class-validator';

export class UpdateBidDto {
  @IsOptional() // Permet de ne pas exiger ce champ si non fourni
  @IsString()
  readonly userId?: string;

  @IsOptional()
  @IsNumber()
  readonly amount?: number;

  @IsOptional()
  @IsString()
  readonly auctionId?: string;
}
