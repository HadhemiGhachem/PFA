import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from 'src/auth/schemas/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{
      name: User.name, schema: UserSchema
    }])
  ],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService],  // Ajoutez ceci pour que UsersService soit accessible dans d'autres modules
})
export class UsersModule {}
