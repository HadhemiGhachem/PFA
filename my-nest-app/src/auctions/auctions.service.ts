import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import mongoose, { Model } from 'mongoose';
import { Auction, AuctionDocument } from './schemas/auction.schema';
import { Car, CarDocument } from 'src/cars/schemas/car.schema';
import { CreateAuctionDto } from './dto/create-auction.dto';
import { UpdateAuctionDto } from './dto/update-auction.dto';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationsService } from 'src/notification/notification.service';

@Injectable()
export class AuctionsService {
  constructor(
    @InjectModel(Auction.name) private auctionModel: Model<AuctionDocument>,
    @InjectModel(Car.name) private carModel: Model<CarDocument>,
    private notificationsService: NotificationsService, // Déclaration correcte
  ) {}




  async create(createAuctionDto: CreateAuctionDto, userId: string): Promise<AuctionDocument> {
    const { startDate, endDate, startingPrice, carId } = createAuctionDto;

    // Vérifier si carId et userId sont valides
    if (!mongoose.Types.ObjectId.isValid(carId) ) {
      throw new BadRequestException('ID de voiture ou utilisateur invalide');
    }

    // Vérifier si la voiture existe
    const car = await this.carModel.findById(carId).exec();
    if (!car) {
      throw new NotFoundException(`Voiture avec l'ID ${carId} non trouvée`);
    }

    // Vérifier si la voiture appartient à l'utilisateur
    if (!car.userId || car.userId.toString() !== userId) {
      throw new BadRequestException('Vous ne pouvez créer une enchère que pour vos propres voitures');
    }

    // Vérifier si le prix de départ est valide
    if (startingPrice <= 0) {
      throw new BadRequestException('Le prix de départ doit être supérieur à 0');
    }

    // Vérifier les dates
    const start = new Date(startDate);
    const end = new Date(endDate);
    const now = new Date();
    if (start < now) {
      throw new BadRequestException('La date de début doit être dans le futur');
    }
    if (end <= start) {
      throw new BadRequestException('La date de fin doit être après la date de début');
    }

    // Créer l'enchère
    const auction = new this.auctionModel({
      startDate: start,
      endDate: end,
      startingPrice,
      currentBid: startingPrice,
      carId,
      userId, // Ajoute userId automatiquement
      status: 'active',
      bidCount: 0,
      bids: [],
      bidders: [],
    });

    return auction.save();
  }




  async update(id: string, updateAuctionDto: UpdateAuctionDto): Promise<AuctionDocument> {
    const auction = await this.auctionModel.findById(id).exec();
    if (!auction) {
      throw new NotFoundException(`Enchère avec l'ID ${id} non trouvée`);
    }

    // Vérifier si la voiture existe (si carId est fourni)
    if (updateAuctionDto.carId) {
      const car = await this.carModel.findById(updateAuctionDto.carId).exec();
      if (!car) {
        throw new NotFoundException(`Voiture avec l'ID ${updateAuctionDto.carId} non trouvée`);
      }
    }

    // Vérifier les dates (si fournies)
    if (updateAuctionDto.startDate && updateAuctionDto.endDate) {
      const start = new Date(updateAuctionDto.startDate);
      const end = new Date(updateAuctionDto.endDate);
      if (end <= start) {
        throw new BadRequestException('La date de fin doit être après la date de début');
      }
    }

    // Mettre à jour l'enchère
    Object.assign(auction, updateAuctionDto);
    return auction.save();
  }

  async delete(id: string): Promise<void> {
    const auction = await this.auctionModel.findById(id).exec();
    if (!auction) {
      throw new NotFoundException(`Enchère avec l'ID ${id} non trouvée`);
    }
    await auction.deleteOne();
  }



  async getAllAuctions(): Promise<any[]> {
    try {
      const auctions = await this.auctionModel
        .find()
        .populate<{ carId: CarDocument }>('carId')
        .lean()
        .exec();

      if (!auctions.length) {
        console.log('Aucune enchère trouvée dans la base de données.');
      }

      const enrichedAuctions = auctions
        .map((auction) => {
          const car = auction.carId as CarDocument;
          if (!car || typeof car === 'string') {
            console.log(`Ignorer l'enchère ${auction._id} en raison de données de voiture invalides ou manquantes`);
            return null;
          }
          return {
            _id: auction._id,
            carDetails: {
              brand: car.brand,
              carModel: car.carModel,
              year: car.year,
              image: car.image,
              licensePlate: car.licensePlate,
              power: car.power,
            },
            startDate: auction.startDate,
            endDate: auction.endDate,
            startingPrice: auction.startingPrice,
            currentBid: auction.currentBid,
            bidCount: auction.bids ? auction.bids.length : 0,
            status: auction.status,
          };
        })
        .filter((auction) => auction !== null);

      return enrichedAuctions;
    } catch (error) {
      console.error('Erreur dans getAllAuctions:', error);
      throw error;
    }
  }








  async findEligibleForBidPage(): Promise<any[]> {
    try {
      const todayUTC = new Date();
      todayUTC.setUTCHours(0, 0, 0, 0);
      console.log('Today UTC:', todayUTC.toISOString());

      const auctions = await this.auctionModel
        .find({
          startDate: { $gte: todayUTC },
          endDate: { $gt: todayUTC },
          status: 'active',
        })
        .populate<{ carId: CarDocument }>('carId')
        .lean()
        .exec();

      console.log('Found eligible auctions:', auctions);

      if (!auctions.length) {
        console.log('No eligible auctions found. Check MongoDB data (startDate, endDate, status, carId).');
      }

      const enrichedAuctions = auctions
        .map((auction) => {
          const car = auction.carId as CarDocument;
          if (!car || typeof car === 'string') {
            console.log(`Skipping auction ${auction._id} due to invalid or missing car data`);
            return null;
          }
          return {
            _id: auction._id,
            carDetails: {
              brand: car.brand,
              carModel: car.carModel,
              year: car.year,
              image: car.image,
              licensePlate: car.licensePlate,
              power: car.power,
            },
            startDate: auction.startDate,
            endDate: auction.endDate,
            startingPrice: auction.startingPrice,
            currentBid: auction.currentBid,
            bidCount: auction.bids ? auction.bids.length : 0,
          };
        })
        .filter((auction) => auction !== null);

      console.log('Enriched auctions:', enrichedAuctions);
      return enrichedAuctions;
    } catch (error) {
      console.error('Error in findEligibleForBidPage:', error);
      throw error;
    }
  }

  async findAllAuctions(): Promise<any[]> {
    try {
      const auctions = await this.auctionModel
        .find()
        .populate<{ carId: CarDocument }>('carId')
        .lean()
        .exec();

      console.log('Found all auctions:', auctions);

      if (!auctions.length) {
        console.log('No auctions found in the database.');
      }

      const enrichedAuctions = auctions
        .map((auction) => {
          const car = auction.carId as CarDocument;
          if (!car || typeof car === 'string') {
            console.log(`Skipping auction ${auction._id} due to invalid or missing car data`);
            return null;
          }
          return {
            _id: auction._id,
            carDetails: {
              brand: car.brand,
              carModel: car.carModel,
              year: car.year,
              image: car.image,
              licensePlate: car.licensePlate,
              power: car.power,
            },
            startDate: auction.startDate,
            endDate: auction.endDate,
            startingPrice: auction.startingPrice,
            currentBid: auction.currentBid,
            bidCount: auction.bids ? auction.bids.length : 0,
          };
        })
        .filter((auction) => auction !== null);

      console.log('Enriched all auctions:', enrichedAuctions);
      return enrichedAuctions;
    } catch (error) {
      console.error('Error in findAllAuctions:', error);
      throw error;
    }
  }

  async placeBid(auctionId: string, bidAmount: number, userId: string) {
    const auction = await this.auctionModel.findById(auctionId);
    if (!auction) {
      throw new NotFoundException('Enchère non trouvée');
    }

    if (new Date() > auction.endDate) {
      throw new BadRequestException('L\'enchère est terminée');
    }

    if (bidAmount <= auction.currentBid) {
      throw new BadRequestException('L\'enchère doit être supérieure à l\'enchère actuelle');
    }

    auction.currentBid = bidAmount;
    auction.bidCount += 1;
    auction.lastBidder = userId;

    await auction.save();
    return { message: 'Enchère soumise avec succès', auction };
  }

  async findOne(id: string): Promise<AuctionDocument> {
    const auction = await this.auctionModel.findById(id).exec();
    if (!auction) {
      throw new NotFoundException(`Enchère avec l'ID ${id} non trouvée`);
    }
    return auction;
  }


  async findUserAuctions(userId: string): Promise<any[]> {
    console.log('Recherche des enchères pour userId:', userId);
    const auctions = await this.auctionModel
      .find({ userId })
      .populate('carId', 'brand carModel year image power licensePlate')
      .exec();
    console.log('Enchères trouvées:', auctions);
  
    const validAuctions = auctions.filter(auction => {
      const isValid =
        auction.carId &&
        typeof auction.carId === 'object' &&
        'brand' in auction.carId &&
        'carModel' in auction.carId;
      if (!isValid) {
        console.log('Enchère invalide:', auction);
      }
      return isValid;
    });
    console.log('Enchères valides:', validAuctions);
  
    return validAuctions.map(auction => ({
      _id: auction._id,
      carDetails: {
        brand: (auction.carId as Car).brand,
        carModel: (auction.carId as Car).carModel,
        year: (auction.carId as Car).year,
        image: (auction.carId as Car).image,
        power: (auction.carId as Car).power,
        licensePlate: (auction.carId as Car).licensePlate,
      },
      startDate: auction.startDate,
      endDate: auction.endDate,
      startingPrice: auction.startingPrice,
      currentBid: auction.currentBid,
      bidCount: auction.bidCount,
      bidders: auction.bidders,
    }));
  }


  @Cron(CronExpression.EVERY_5_MINUTES)
  async checkEndedAuctions() {
    const now = new Date();
    const endedAuctions = await this.auctionModel
      .find({ endDate: { $lte: now }, isNotified: { $ne: true } })
      .populate('carId') // Populer carId pour accéder aux détails de la voiture
      .exec();

      for (const auction of endedAuctions) {
        if (auction.bidders.length === 1 && auction.carId && 'brand' in auction.carId) {
          // Vérifier que carId est un objet Car et a la propriété brand
          const winnerId = auction.bidders[0];
          const car = auction.carId as Car; // Typage explicite après vérification
          await this.notificationsService.createNotification(
            winnerId,
            'Félicitations ! Vous avez gagné une enchère',
            `Vous avez remporté l'enchère pour ${car.brand || 'Voiture'} ${car.carModel || ''} !`,
            auction._id.toString(),
            'auction_won',
          );
  
          // Marquer l'enchère comme notifiée
          await this.auctionModel.findByIdAndUpdate(auction._id, { isNotified: true }).exec();
        }
      }
  }
}
