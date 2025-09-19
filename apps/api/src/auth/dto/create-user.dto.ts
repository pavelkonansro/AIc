import { IsString, IsNotEmpty, IsIn, IsOptional, Length } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ 
    description: 'Имя пользователя',
    example: 'Алекс',
    minLength: 2,
    maxLength: 20,
  })
  @IsString()
  @IsNotEmpty()
  @Length(2, 20)
  nick: string;

  @ApiProperty({ 
    description: 'Возрастная группа',
    enum: ['9-12', '13-15', '16-18'],
    example: '13-15',
  })
  @IsString()
  @IsIn(['9-12', '13-15', '16-18'])
  ageGroup: string;

  @ApiProperty({ 
    description: 'Локаль пользователя',
    enum: ['en-US', 'cs-CZ', 'de-DE'],
    example: 'cs-CZ',
  })
  @IsString()
  @IsIn(['en-US', 'cs-CZ', 'de-DE'])
  locale: string;

  @ApiProperty({ 
    description: 'Код страны',
    enum: ['US', 'CZ', 'DE'],
    example: 'CZ',
  })
  @IsString()
  @IsIn(['US', 'CZ', 'DE'])
  country: string;

  @ApiProperty({ 
    description: 'Флаги согласия пользователя',
    example: 'terms:true,privacy:true,marketing:false',
    required: false,
  })
  @IsOptional()
  @IsString()
  consentFlags?: string;
}


