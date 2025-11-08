import 'package:flutter/material.dart';
import '../../data/models/swap_model.dart';
import '../../data/models/book_model.dart';
import '../../data/services/swap_service.dart';
import '../../core/constants/app_constants.dart';

class SwapProvider extends ChangeNotifier {
  final SwapService _swapService = SwapService();
  
  List<SwapModel> _userSwaps = [];
  List<SwapModel> _receivedSwaps = [];
  bool _isLoading = false;
  String? _error;

  List<SwapModel> get userSwaps => _userSwaps;
  List<SwapModel> get sentSwaps => _userSwaps;
  List<SwapModel> get receivedSwaps => _receivedSwaps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SwapModel> get pendingSwaps => _userSwaps
      .where((swap) => swap.status == AppConstants.swapPending)
      .toList();

  void listenToUserSwaps(String userId) {
    // Listen to sent swaps
    _swapService.getUserSwaps(userId).listen((swaps) {
      _userSwaps = swaps;
      notifyListeners();
    });
    
    // Listen to received swaps
    _swapService.getReceivedSwaps(userId).listen((swaps) {
      _receivedSwaps = swaps;
      notifyListeners();
    });
  }

  Future<bool> createSwapRequest(
    BookModel targetBook,
    BookModel offeredBook,
    String requesterId,
    String requesterName,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _swapService.createSwapRequest(
        targetBook: targetBook,
        offeredBook: offeredBook,
        requesterId: requesterId,
        requesterName: requesterName,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> acceptSwap(String swapId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _swapService.updateSwapStatus(
        swapId: swapId,
        status: AppConstants.swapAccepted,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> rejectSwap(String swapId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _swapService.updateSwapStatus(
        swapId: swapId,
        status: AppConstants.swapRejected,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  Future<bool> updateSwapStatus(String swapId, String status) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _swapService.updateSwapStatus(
        swapId: swapId,
        status: status,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelSwap(String swapId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _swapService.cancelSwap(swapId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}