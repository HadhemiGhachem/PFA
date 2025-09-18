import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { signupDto } from './dtos/signup.dto';
import { LoginDto } from './dtos/login.dto';


@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  async signUp(@Body() signupData : signupDto) {
    const response = await  this.authService.signup(signupData) 
    
   return response
  }

  @Post('login')
  async login(@Body() credentials : LoginDto) {
    return this.authService.login(credentials)
  }



}
