import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Notification {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  message: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Car' })
  carId?: Types.ObjectId;

  @Prop({ required: true })
  type: string;

  @Prop({ default: false })
  isRead: boolean;

  // Timestamps are guaranteed by timestamps: true
  createdAt: Date;
  updatedAt: Date;
}

export type NotificationDocument = Notification & Document<Types.ObjectId>;
export const NotificationSchema = SchemaFactory.createForClass(Notification);