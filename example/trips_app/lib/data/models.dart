/// A place to stay.
class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.price,
    required this.rating,
  });

  final String id;
  final String name;
  final String city;

  /// A night's price, in yen.
  final int price;
  final double rating;
}

/// A city the app suggests.
class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.blurb,
  });

  final String id;
  final String name;
  final String blurb;
}

/// A room of a hotel.
class Room {
  const Room({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final int price;
}

/// What a guest wrote of a hotel.
class Review {
  const Review({required this.author, required this.text, required this.stars});

  final String author;
  final String text;
  final int stars;
}

/// A stay booked.
class Trip {
  const Trip({
    required this.id,
    required this.hotel,
    required this.room,
    required this.dates,
  });

  final String id;
  final Hotel hotel;
  final Room room;
  final String dates;
}

/// A thread with a hotel.
class Conversation {
  const Conversation({
    required this.id,
    required this.hotelName,
    required this.lastMessage,
  });

  final String id;
  final String hotelName;
  final String lastMessage;
}

/// What the app tells the user of (a trip coming, a price that fell).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.text,
    required this.tripId,
  });

  final String id;
  final String text;

  /// The trip it is about.
  final String tripId;
}

/// A payment card kept for booking.
class PaymentCard {
  const PaymentCard({required this.brand, required this.last4});

  final String brand;
  final String last4;
}
