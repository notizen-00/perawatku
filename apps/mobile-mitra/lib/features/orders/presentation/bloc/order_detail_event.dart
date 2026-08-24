part of 'order_detail_bloc.dart';

abstract class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();

  @override
  List<Object?> get props => [];
}

class OrderDetailRequested extends OrderDetailEvent {
  const OrderDetailRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailRefreshed extends OrderDetailEvent {
  const OrderDetailRefreshed(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailAccepted extends OrderDetailEvent {
  const OrderDetailAccepted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailRejected extends OrderDetailEvent {
  const OrderDetailRejected(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailJourneyStarted extends OrderDetailEvent {
  const OrderDetailJourneyStarted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailArrived extends OrderDetailEvent {
  const OrderDetailArrived(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailTreatmentStarted extends OrderDetailEvent {
  const OrderDetailTreatmentStarted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class OrderDetailTindakanAdded extends OrderDetailEvent {
  const OrderDetailTindakanAdded({
    required this.id,
    required this.title,
    required this.description,
    required this.checklist,
    this.photoPath,
  });

  final int id;
  final String title;
  final String description;
  final List<String> checklist;
  final String? photoPath;

  @override
  List<Object?> get props => [id, title, description, checklist, photoPath];
}

class OrderDetailCompleted extends OrderDetailEvent {
  const OrderDetailCompleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
