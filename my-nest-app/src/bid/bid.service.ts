import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Bid, BidDocument } from './schemas/bid.schema';
import { CreateBidDto } from './dto/create-bid.dto';
import { UsersService } from '../users/users.service';
import { AuctionsService } from '../auctions/auctions.service';
import { UpdateBidDto } from './dto/update-bid.dto';

@Injectable()
export class BidService {
  constructor(
    @InjectModel(Bid.name) private bidModel: Model<Bid>,
    private usersService: UsersService,  // Injection correcte du UsersService
    private auctionsService: AuctionsService,
  ) {}

  async findAll(): Promise<Bid[]> {
    return this.bidModel.find().exec();
  }

  async findOne(id: string): Promise<Bid | null> {
    return this.bidModel.findById(id).exec();
  }

  async create(createBidDto: CreateBidDto, userId: string): Promise<BidDocument> {
    try {
      const auction = await this.auctionsService.findOne(createBidDto.auctionId);

      if (new Date() > auction.endDate) {
        throw new BadRequestException("L'enchère est terminée");
      }

      if (createBidDto.bidAmount <= auction.currentBid) {
        throw new BadRequestException(
          `L'enchère doit être supérieure à ${auction.currentBid} €`,
        );
      }

      const bid = new this.bidModel({
        auctionId: createBidDto.auctionId,
        userId,
        bidAmount: createBidDto.bidAmount,
        createdAt: new Date(),
      });

      await this.auctionsService.placeBid(
        createBidDto.auctionId,
        createBidDto.bidAmount,
        userId,
      );

      return bid.save();
    } catch (error) {
      throw new BadRequestException(error.message || 'Erreur lors de la soumission de l\'enchère');
    }
  }

  async remove(id: string): Promise<boolean> {
    const result = await this.bidModel.findByIdAndDelete(id).exec();
    return !!result; // Retourne true si supprimée, false sinon
  }

  async update(id: string, updateBidDto: UpdateBidDto): Promise<Bid> {
    const updatedBid = await this.bidModel.findByIdAndUpdate(id, updateBidDto, { new: true });
    if (!updatedBid) {
      throw new Error(`Bid with id ${id} not found`);
    }
    return updatedBid;
  }
}
