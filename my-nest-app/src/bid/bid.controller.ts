import { Controller, Get, Post, Param, Body, Delete, UsePipes, ValidationPipe, NotFoundException, HttpException, HttpStatus, Put, HttpCode, UseGuards, Request, UnauthorizedException } from '@nestjs/common';
import { BidService } from './bid.service';
import { Bid } from './schemas/bid.schema';
import { CreateBidDto } from './dto/create-bid.dto';
import { UpdateBidDto } from './dto/update-bid.dto';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';

@Controller('bids')
export class BidController {
  constructor(private readonly bidService: BidService) {}

  @Post('createBid')
  @UsePipes(new ValidationPipe()) // Validation automatique


  async create(
    @Param('auctionId') auctionId: string,
    @Body() createBidDto: CreateBidDto,
    @Request() req,
  ) {
    if (!req.user || !req.user.userId) {
      throw new UnauthorizedException('Utilisateur non authentifié');
    }
    createBidDto.auctionId = auctionId;
    return this.bidService.create(createBidDto, req.user.userId);
  }

  @Get('getAllBids')
  findAll(): Promise<Bid[]> {
    return this.bidService.findAll();
  }

  @Get('getBidById/:id')
  findOne(@Param('id') id: string): Promise<Bid | null> {
    return this.bidService.findOne(id);
  }

  @Put('updateBid/:id')
  async update(@Param('id') id: string, @Body() updateBidDto: UpdateBidDto): Promise<Bid> {
    return this.bidService.update(id, updateBidDto);
  }
  

@Delete('deleteBid/:id')
  async remove(@Param('id') id: string): Promise<{ message: string }> {
    const result = await this.bidService.remove(id);

    if (result) {
      return { message: 'Bid deleted' }; // Renvoie un message si la suppression réussie
    } else {
      throw new HttpException('Bid not found', HttpStatus.NOT_FOUND); // En cas d'échec
    }
  }

 
}
