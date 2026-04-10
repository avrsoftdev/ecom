import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/category_entity.dart';

abstract class AdminCategoryRepository {
  Stream<List<CategoryEntity>> watchCategories();

  Future<Either<Failure, String>> create(CategoryEntity category);

  Future<Either<Failure, void>> update(String id, CategoryEntity category);

  Future<Either<Failure, void>> delete(String id);
}
