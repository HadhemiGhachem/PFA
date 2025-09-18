import { IsEmail, IsString, Matches, MinLength } from "class-validator";

export class signupDto {
        @IsString()
        firstname : String;
    
        @IsString()
        lastname : String;

        @IsEmail()
        email : String;

        @IsString()
        @MinLength(6)
        @Matches(/^(?=.*[0-9])/, {message: 'Password must contain at least one number'})
        password : String;
}