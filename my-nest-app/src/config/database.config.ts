import { ConfigService } from '@nestjs/config';

export const getMongoConfig = (configService: ConfigService) => {
  const uri = configService.get<string>('DATABASE_URL');
  
  if (!uri) {
    console.error('❌ Erreur : DATABASE_URL est manquant dans .env');
    throw new Error('DATABASE_URL is not defined in environment variables');
  }

  console.log(`✅ Connexion à MongoDB avec l'URL : ${uri}`);

  return {
    uri,
    useNewUrlParser: true,
    useUnifiedTopology: true,
  };
};
