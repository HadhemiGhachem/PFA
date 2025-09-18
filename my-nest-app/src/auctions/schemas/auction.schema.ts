import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { Car } from 'src/cars/schemas/car.schema';

export type AuctionDocument = Auction & Document;

@Schema({ timestamps: true })
export class Auction {
  _id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: Car.name, required: true })
  carId: Types.ObjectId | Car;

  @Prop({ type: Types.ObjectId, ref: 'User' }) 
  userId: Types.ObjectId;
  
  @Prop({ required: true })
  startDate: Date;

  @Prop({ required: true })
  endDate: Date;

  @Prop({ required: true })
  startingPrice: number;

  @Prop({ default: 0 })
  currentBid: number;

  @Prop({ default: 'active' })
  status: string;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], default: [] })
  bids: Types.ObjectId[];

  @Prop({ default: 0 })
  bidCount: number;

  @Prop()
  lastBidder: string;

  @Prop({ type: [{ type: String }], default: [] })
  bidders: string[];

  @Prop({ default: false })
  isNotified: boolean; // Nouveau champ
  

}
export const AuctionSchema = SchemaFactory.createForClass(Auction);
// Interface pour une enchère avec carId populé
export interface PopulatedAuction extends Auction {
  carId: Car; // carId est un objet Car après population
}