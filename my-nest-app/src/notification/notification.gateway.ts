import { WebSocketGateway, SubscribeMessage, MessageBody, WsResponse, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Injectable, Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { NotificationDto } from './dto/notification.dto';

@WebSocketGateway()
@Injectable()

@WebSocketGateway({
  cors: {
    origin: ['http://10.0.2.2:6006', 'http://localhost:6006'], // Ajustez pour votre environnement
    credentials: true,
  },
})

export class NotificationGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(NotificationGateway.name);
  private userSockets: Map<string, string> = new Map(); // Mappe userId à socketId


  constructor(private readonly jwtService: JwtService) {
    this.logger.log('WebSocket Gateway initialized');
  }

  afterInit() {
    this.logger.log('WebSocket Gateway initialized');
  }



async handleConnection(client: Socket) {
    try {
      const token = client.handshake.query.token as string;
      if (!token) {
        this.logger.warn('No token provided, disconnecting client');
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      const userId = payload.userId;
      if (!userId) {
        this.logger.warn('Invalid token, disconnecting client');
        client.disconnect();
        return;
      }

      this.userSockets.set(userId, client.id);
      this.logger.log(`Client connected: ${client.id}, User ID: ${userId}`);
    } catch (error) {
      this.logger.error(`Connection error: ${error.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    for (const [userId, socketId] of this.userSockets.entries()) {
      if (socketId === client.id) {
        this.userSockets.delete(userId);
        this.logger.log(`Client disconnected: ${client.id}, User ID: ${userId}`);
        break;
      }
    }
  }


  async sendNotificationToUser(userId: string, notification: NotificationDto) {
    const socketId = this.userSockets.get(userId);
    if (socketId) {
      this.server.to(socketId).emit('newNotification', notification);
      this.logger.log(`Notification sent to user ${userId} via socket ${socketId}`);
    } else {
      this.logger.warn(`No socket found for user ${userId}`);
    }
  }
}
