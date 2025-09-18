import { Body, Controller, Delete, Get, NotFoundException, Param, Patch, Post, Request, UnauthorizedException, UseGuards } from '@nestjs/common';
import { UpdateUserDto } from './dtos/update-user.dto';
import { UserProfileDto } from './dtos/user-profile.dto';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateUserDto } from './dtos/createUser.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('createUser')
  async createUser(@Body() createUserDto: CreateUserDto): Promise<UserProfileDto> {
    const user = await this.usersService.createUser(createUserDto);
    return {
      id: user.id,
      firstname: user.firstname,
      lastname: user.lastname,
      email: user.email,
    };
  }

  @Get('getAllUsers')
  @UseGuards(JwtAuthGuard)
  async findAll(): Promise<UserProfileDto[]> {
    const users = await this.usersService.findAll();
    return users.map(user => ({
      id: user.id,
      firstname: user.firstname,
      lastname: user.lastname,
      email: user.email,
    }));
  }

  @Get('getUserById/:id')
  @UseGuards(JwtAuthGuard)
  async findById(@Param('id') id: string): Promise<UserProfileDto> {
    const user = await this.usersService.findById(id);
    if (!user) {
      throw new NotFoundException(`Utilisateur avec l'ID ${id} non trouvé`);
    }
    return {
      id: user.id,
      firstname: user.firstname,
      lastname: user.lastname,
      email: user.email,
    };
  }

// UsersController
@Get('profile')
@UseGuards(JwtAuthGuard)
async getProfile(@Request() req): Promise<UserProfileDto> {
  console.log('[DEBUG] User object from token:', req.user);
  const userId = req.user.userId; // Should now work
  if (!userId) {
    throw new UnauthorizedException('User ID not found in token');
  }
  const profile = await this.usersService.findById(userId);
  console.log('[DEBUG] Profile data:', profile);
  if (!profile) {
    throw new NotFoundException('User profile not found');
  }
  return profile;
}

@Patch('updateUser')
@UseGuards(JwtAuthGuard)
async updateProfile(
  @Request() req,
  @Body() updateData: UpdateUserDto,
): Promise<UserProfileDto> {
  const userId = req.user.userId;
  return this.usersService.updateProfile(userId, updateData);
}

  @Patch('updateUser/:id')
  @UseGuards(JwtAuthGuard)
  async updateProfileById(
    @Param('id') userId: string,
    @Body() updateData: UpdateUserDto,
  ): Promise<UserProfileDto> {
    return this.usersService.updateProfile(userId, updateData);
  }

  @Delete('deleteUser')
  @UseGuards(JwtAuthGuard)
  async deleteUser(@Request() req): Promise<{ message: string }> {
    const userId = req.user.userId;
    await this.usersService.deleteUser(userId);
    return { message: 'Compte supprimé avec succès' };
  }

  @Delete('deleteUser/:id')
  @UseGuards(JwtAuthGuard)
  async deleteUserById(@Param('id') userId: string): Promise<{ message: string }> {
    await this.usersService.deleteUser(userId);
    return { message: 'Compte supprimé avec succès' };
  }
}