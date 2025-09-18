import { Body, Controller, Delete, Get, HttpCode, Param, Post, Put, Request, UseGuards } from '@nestjs/common';
import { AuctionsService } from './auctions.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { CreateAuctionDto } from './dto/create-auction.dto';
import { UpdateAuctionDto } from './dto/update-auction.dto';
import { AuctionDocument } from './schemas/auction.schema';

@Controller('auctions')
export class AuctionsController {
  constructor(private readonly auctionsService: AuctionsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('createAuction')
  async create(@Body() createAuctionDto: CreateAuctionDto, @Request() req): Promise<AuctionDocument> {
    return this.auctionsService.create(createAuctionDto, req.user.userId);
  }

  @Get('getAllAuctions')
  async getAll() {
    return this.auctionsService.getAllAuctions();
  }

  @Put('updateAuction:id')
  async update(@Param('id') id: string, @Body() updateAuctionDto: UpdateAuctionDto) {
    return this.auctionsService.update(id, updateAuctionDto);
  }

  @Delete('deleteAuction:id')
  async delete(@Param('id') id: string) {
    await this.auctionsService.delete(id);
    return { message: `Enchère avec l'ID ${id} supprimée avec succès` };
  }

  @Get('bid-eligible')
  async findEligibleForBidPage() {
    return this.auctionsService.findEligibleForBidPage();
  }

  @Get('all')
  async findAllAuctions() {
    return this.auctionsService.findAllAuctions();
  }

  @Post(':auctionId/bid')
  @HttpCode(201)
  @UseGuards(JwtAuthGuard)
  async placeBid(
    @Param('auctionId') auctionId: string,
    @Body('bidAmount') bidAmount: number,
    @Request() req,
  ) {
    return this.auctionsService.placeBid(auctionId, bidAmount, req.user.userId);
  }

  @Get('user')
@UseGuards(JwtAuthGuard)
async findUserAuctions(@Request() req) {
  console.log(`User ID from JWT: ${req.user.userId}`);
  return this.auctionsService.findUserAuctions(req.user.userId);
}
}