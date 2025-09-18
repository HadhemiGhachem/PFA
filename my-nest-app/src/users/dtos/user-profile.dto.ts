import { IsString, IsEmail } from 'class-validator';

export class UserProfileDto {
  @IsString()
  id: string;

  @IsString()
  firstname: string;

  @IsString()
  lastname: string;

  @IsEmail()
  email: string;
}