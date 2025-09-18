import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BidService } from './bid.service';
import { BidController } from './bid.controller';
import { Bid, BidSchema } from './schemas/bid.schema';
import { UsersModule } from '../users/users.module';  // Importez le UsersModule ici
import { AuctionsModule } from 'src/auctions/auctions.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Bid.name, schema: BidSchema }]),
    UsersModule,  // Ajoutez UsersModule ici
    AuctionsModule,  
  ],
  controllers: [BidController],
  providers: [BidService],
})
export class BidModule {}
