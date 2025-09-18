import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuctionsController } from './auctions.controller';
import { AuctionsService } from './auctions.service';
import { Auction, AuctionSchema } from './schemas/auction.schema';
import { Car, CarSchema } from '../cars/schemas/car.schema';
import { NotificationsModule } from 'src/notification/notification.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Auction.name, schema: AuctionSchema },
      { name: Car.name, schema: CarSchema },
    ]),
    NotificationsModule
  ],
  controllers: [AuctionsController],
  providers: [AuctionsService],
  exports: [AuctionsService],

})
export class AuctionsModule {}