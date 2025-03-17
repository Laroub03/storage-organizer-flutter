import 'dart:convert';
import 'dart:io';
import 'package:barcodescanner/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({this.baseUrl = 'https://nordicsupplies.net/api'});

  // Set token after successful login
  void setToken(String token) {
    _token = token;
  }

  // Get headers for authenticated requests
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  // Get headers for multipart requests
  Map<String, String> _getMultipartAuthHeaders() {
    return {
      'Authorization': 'Bearer $_token',
    };
  }

  // Check if the user is authenticated
  bool isAuthenticated() {
    return _token != null;
  }

  // AUTHENTICATION

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['accessToken']);
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid credentials');
    } else {
      throw Exception('Failed to login: ${response.reasonPhrase}');
    }
  }

  // USERS

  // Get all users
  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get users: ${response.reasonPhrase}');
    }
  }

  // Get user by username
  Future<User> getUserByUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$username'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Failed to get user: ${response.reasonPhrase}');
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=$query'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users: ${response.reasonPhrase}');
    }
  }

  // Create user
  Future<User> createUser(Map<String, dynamic> userData,
      {bool makeAdmin = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/create?makeAdmin=$makeAdmin'),
      headers: _getAuthHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('Username or email already exists');
    } else {
      throw Exception('Failed to create user: ${response.reasonPhrase}');
    }
  }

  // Update user
  Future<User> updateUser(String username, Map<String, dynamic> userData,
      {bool makeAdmin = false}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$username?makeAdmin=$makeAdmin'),
      headers: _getAuthHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else if (response.statusCode == 400) {
      throw Exception('Invalid data');
    } else {
      throw Exception('Failed to update user: ${response.reasonPhrase}');
    }
  }

  // Delete user
  Future<void> deleteUser(String username) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$username'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Failed to delete user: ${response.reasonPhrase}');
    }
  }

  // Upload user image
  Future<int> uploadUserImage(int userId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/$userId/image'),
    );

    request.headers.addAll(_getMultipartAuthHeaders());

    final fileStream = http.ByteStream(imageFile.openRead());
    final fileLength = await imageFile.length();

    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: imageFile.path.split('/').last,
      contentType: MediaType('image', imageFile.path.split('.').last),
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      throw Exception('Invalid image or user ID');
    } else {
      throw Exception('Failed to upload user image: ${response.reasonPhrase}');
    }
  }

  // Get user image
  Future<Uint8List> getUserImage(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/image'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else if (response.statusCode == 404) {
      throw Exception('User has no image');
    } else {
      throw Exception('Failed to get user image: ${response.reasonPhrase}');
    }
  }

  // Delete user image
  Future<void> deleteUserImage(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/image'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('User has no image');
    } else {
      throw Exception('Failed to delete user image: ${response.reasonPhrase}');
    }
  }

  // PRODUCTS

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      print('Get All Products Response: ${response.body}');
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get products: ${response.reasonPhrase}');
    }
  }

// Get product by ID
  Future<Product> getProductById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      print('Get Product by ID Response: ${response.body}');
      return Product.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Product not found');
    } else {
      throw Exception('Failed to get product: ${response.reasonPhrase}');
    }
  }

// Search products
  Future<List<Product>> searchProducts(
      {String? query, String? category}) async {
    String url = '$baseUrl/products/search?';

    if (query != null) {
      url += 'q=$query';
    }

    if (category != null) {
      url += '${query != null ? '&' : ''}c=$category';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      print('Search Products Response: ${response.body}');
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products: ${response.reasonPhrase}');
    }
  }

// Create product
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    print('Sending request with data: $productData');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _getAuthHeaders(),
        body: jsonEncode(productData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid data');
      } else {
        throw Exception('Failed to create product: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow; // Rethrow to handle further if needed
    }
  }

// Update product
  Future<Product> updateProduct(
      int id, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getAuthHeaders(),
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      print('Update Product Response: ${response.body}');
      return Product.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Product not found');
    } else if (response.statusCode == 400) {
      throw Exception('Invalid data');
    } else {
      throw Exception('Failed to update product: ${response.reasonPhrase}');
    }
  }

// Delete product
  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Product not found');
    } else {
      throw Exception('Failed to delete product: ${response.reasonPhrase}');
    }
  }

  // CATEGORIES

  // Get category hierarchy
  Future<CategoryHierarchy> getCategoryHierarchy() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return CategoryHierarchy.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get categories: ${response.reasonPhrase}');
    }
  }

  // Get all parent categories
  Future<List<ParentCategoryModel>> getAllParentCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/parent'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => ParentCategoryModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to get parent categories: ${response.reasonPhrase}');
    }
  }

  // Get parent category by name
  Future<ParentCategoryModel> getParentCategoryByName(String name) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/parent/$name'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return ParentCategoryModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Category not found');
    } else {
      throw Exception(
          'Failed to get parent category: ${response.reasonPhrase}');
    }
  }

  // Create parent category
  Future<ParentCategoryModel> createParentCategory(
      Map<String, String> categoryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/parent'),
      headers: _getAuthHeaders(),
      body: jsonEncode(categoryData),
    );

    if (response.statusCode == 201) {
      return ParentCategoryModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      throw Exception('Invalid data');
    } else {
      throw Exception(
          'Failed to create parent category: ${response.reasonPhrase}');
    }
  }

  // Delete parent category
  Future<void> deleteParentCategory(String name) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/parent/$name'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 400) {
      throw Exception('Error deleting parent category (may have children)');
    } else {
      throw Exception(
          'Failed to delete parent category: ${response.reasonPhrase}');
    }
  }

  // Delete parent category with children
  Future<void> deleteParentCategoryWithChildren(String name) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/parent/$name/with-children'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 400) {
      throw Exception('Error deleting parent category');
    } else {
      throw Exception(
          'Failed to delete parent category with children: ${response.reasonPhrase}');
    }
  }

  // Get child categories by parent
  Future<List<CategoryModel>> getChildCategoriesByParent(
      String parentName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$parentName'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => CategoryModel.fromJson(json, parentName: parentName))
          .toList();
    } else if (response.statusCode == 404) {
      throw Exception('Parent not found');
    } else {
      throw Exception(
          'Failed to get child categories: ${response.reasonPhrase}');
    }
  }

  // Get specific child category
  Future<CategoryModel> getChildCategory(
      String parentName, String categoryName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$parentName/$categoryName'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return CategoryModel.fromJson(jsonDecode(response.body),
          parentName: parentName);
    } else if (response.statusCode == 404) {
      throw Exception('Category not found');
    } else {
      throw Exception('Failed to get child category: ${response.reasonPhrase}');
    }
  }

  // Create child category
  Future<CategoryModel> createChildCategory(
      String parentName, String categoryName,
      {String? description}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/$parentName/$categoryName'),
      headers: _getAuthHeaders(),
      body: description != null ? jsonEncode(description) : null,
    );

    if (response.statusCode == 201) {
      return CategoryModel.fromJson(jsonDecode(response.body),
          parentName: parentName);
    } else if (response.statusCode == 400) {
      throw Exception('Invalid data');
    } else {
      throw Exception(
          'Failed to create child category: ${response.reasonPhrase}');
    }
  }

  // Delete child category
  Future<void> deleteChildCategory(
      String parentName, String categoryName) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$parentName/$categoryName'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Category not found');
    } else {
      throw Exception(
          'Failed to delete child category: ${response.reasonPhrase}');
    }
  }

  // LOCATIONS

  // Get all locations
  Future<List<LocationModel>> getAllLocations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => LocationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get locations: ${response.reasonPhrase}');
    }
  }

  // Get location by name
  Future<LocationModel> getLocationByName(String name) async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations/$name'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return LocationModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Location not found');
    } else {
      throw Exception('Failed to get location: ${response.reasonPhrase}');
    }
  }

  // Create location
  Future<LocationModel> createLocation(
      String name, Map<String, String> locationData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/locations/$name'),
      headers: _getAuthHeaders(),
      body: jsonEncode(locationData),
    );

    if (response.statusCode == 201) {
      return LocationModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      throw Exception('Invalid data');
    } else {
      throw Exception('Failed to create location: ${response.reasonPhrase}');
    }
  }

  // Update location
  Future<LocationModel> updateLocation(
      String name, Map<String, String> locationData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/locations/$name'),
      headers: _getAuthHeaders(),
      body: jsonEncode(locationData),
    );

    if (response.statusCode == 200) {
      return LocationModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      throw Exception('Invalid data');
    } else {
      throw Exception('Failed to update location: ${response.reasonPhrase}');
    }
  }

  // Delete location
  Future<void> deleteLocation(String name) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/locations/$name'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 400) {
      throw Exception('Error deleting location (may be in use)');
    } else {
      throw Exception('Failed to delete location: ${response.reasonPhrase}');
    }
  }

  // IMAGES

  // Get image by ID
  Future<Uint8List> getImageById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/images/$id'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else if (response.statusCode == 404) {
      throw Exception('Image not found');
    } else {
      throw Exception('Failed to get image: ${response.reasonPhrase}');
    }
  }

  // Get product image metadata
  Future<ImageMetadata> getProductImage(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/images/product/$productId'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return ImageMetadata.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('No image for product');
    } else {
      throw Exception('Failed to get product image: ${response.reasonPhrase}');
    }
  }

  // Get complete image data (metadata + bytes) for a product
  Future<ImageData> getProductImageData(int productId) async {
    final metadata = await getProductImage(productId);
    final bytes = await getImageById(metadata.id);
    return ImageData(metadata: metadata, bytes: bytes);
  }

  // Upload image for product
  Future<int> uploadProductImage(int productId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/images/upload/$productId'),
    );

    request.headers.addAll(_getMultipartAuthHeaders());

    final fileStream = http.ByteStream(imageFile.openRead());
    final fileLength = await imageFile.length();

    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: imageFile.path.split('/').last,
      contentType: MediaType('image', imageFile.path.split('.').last),
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      throw Exception('Invalid file or product ID');
    } else {
      throw Exception(
          'Failed to upload product image: ${response.reasonPhrase}');
    }
  }

  // Delete image
  Future<void> deleteImage(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/images/$id'),
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Image not found');
    } else {
      throw Exception('Failed to delete image: ${response.reasonPhrase}');
    }
  }

  // Create multiple products in batch
  Future<List<Product>> createProductsBatch(
      List<Map<String, dynamic>> productsData) async {
    try {
      print('Sending batch request with data: $productsData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/products/batch'),
        headers: _getAuthHeaders(),
        body: jsonEncode(productsData),
      );
      
      print('Batch response status code: ${response.statusCode}');
      print('Batch response body: ${response.body}');

      if (response.statusCode == 201) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 400) {
        throw Exception('Invalid data: ${response.body}');
      } else {
        throw Exception('Failed to create products: ${response.statusCode} - ${response.reasonPhrase} - ${response.body}');
      }
    } catch (e) {
      print('Error in createProductsBatch: $e');
      rethrow;
    }
  }
}
