// src/cars/schemas/car.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CarDocument = Car & Document;

@Schema({
  toJSON: {
    transform: (doc, ret) => {
      ret.id = ret._id?.toString() || null;
      ret.userId = ret.userId ? ret.userId.toString() : null; // Gestion de userId manquant
      delete ret._id;
      delete ret.__v;
      return ret;
    },
  },
  toObject: {
    transform: (doc, ret) => {
      ret.id = ret._id?.toString() || null;
      ret.userId = ret.userId ? ret.userId.toString() : null; // Gestion de userId manquant
      delete ret._id;
      delete ret.__v;
      return ret;
    },
  },
})
export class Car {
  @Prop({ required: true })
  licensePlate: string;

  @Prop({ required: true })
  chassisNumber: string;

  @Prop({ required: true })
  brand: string;

  @Prop({ required: true })
  carModel: string;

  @Prop({ required: true })
  year: number;

  @Prop({ required: true })
  cylinders: number;

  @Prop({ required: true })
  currentCard: string;

  @Prop({ required: true })
  power: number;

  @Prop({ required: true })
  speed: number;

  @Prop({ required: true })
  lights: string;

  @Prop({ required: true })
  assistance: string;

  @Prop({ required: true })
  seats: number;

  @Prop({ required: true })
  airConditioning: boolean;

  @Prop({ required: true })
  screen: boolean;

  @Prop({ required: true })
  image: string;

  @Prop()
  hasSunroof?: boolean;

  @Prop({
    type: {
      clean: Boolean,
      stained: Boolean,
      torn: Boolean,
      heated: Boolean,
      electric: Boolean,
    },
  })
  seatCondition?: {
    clean: boolean;
    stained: boolean;
    torn: boolean;
    heated: boolean;
    electric: boolean;
  };

  @Prop()
  auctionDuration?: number;

  @Prop()
  auctionStartDate?: string;

  @Prop()
  auctionEndDate?: string;

  @Prop()
  initialPrice?: number;

  @Prop({ type: Types.ObjectId, required: true })
  userId: Types.ObjectId;
}

export const CarSchema = SchemaFactory.createForClass(Car);