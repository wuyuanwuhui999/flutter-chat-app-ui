import '../common/constant.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ResponseModel<T> {
  final String status;
  final String? msg;
  final int? total;
  final String? token;
  final T data;
  ResponseModel({
    required this.status,
    this.msg,
    this.total,
    this.token,
    required this.data
  });

  //工厂模式-用这种模式可以省略New关键字
  factory ResponseModel.fromJson(dynamic json) {
    return ResponseModel(
        status:json["status"],
        msg:json["msg"],
        total:json["total"],
        token:json["token"],
        data:json["data"] as T);
  }
}

// 网络请求工具类
class HttpUtil {
  static HttpUtil instance = HttpUtil();
  late Dio dio;
  late BaseOptions options;
  late String token;

  void setToken(String mToken){
    token = mToken;
  }

  static HttpUtil getInstance(){
    return instance;
  }

  HttpUtil(){
    //BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
    options = BaseOptions(
      //请求基地址,可以包含子路径
      baseUrl: HOST,
      //连接服务器超时时间，单位是毫秒.
      connectTimeout: const Duration(seconds: 10),
      //响应流上前后两次接受到数据的间隔，单位为毫秒。
      receiveTimeout: const Duration(seconds: 20),
      //Http请求头.
      headers: {
        //do something
        "version": "1.0.0",
        // 'Content-Type':'application/json '
      },
      //请求的Content-Type，默认值是"application/json; charset=utf-8",Headers.formUrlEncodedContentType会自动编码请求体.
      contentType: Headers.jsonContentType,
      //表示期望以那种格式(方式)接受响应数据。接受4种类型 `json`, `stream`, `plain`, `bytes`. 默认值是 `json`,
      responseType: ResponseType.json,
    );
    dio = Dio(options);
    // 添加请求后拦截器
    dio.interceptors.add(InterceptorsWrapper(
        onResponse: (Response response, ResponseInterceptorHandler handler){
          if (response.statusCode == 200 && response.data["status"] == SUCCESS) {
            return handler.next(response); // 继续
          } else {
            throw Exception('后端接口出现异常，请检测代码和服务器情况.........');
          }
        },
        onRequest: (RequestOptions options, RequestInterceptorHandler handler){
          options.headers['Authorization'] = token;
          return handler.next(options); // 继续
        },
        onError: (DioException err, ErrorInterceptorHandler handler){
          return handler.next(err); // 继续
        }
    ));
  }

  /// 文件上传方法
  /// [filePath] 文件路径
  /// [fileName] 文件名
  /// [uploadUrl] 上传地址（相对路径，会自动拼接baseUrl）
  /// [formData] 额外的表单数据
  Future<ResponseModel> uploadFile({
    required String filePath,
    required String fileName,
    required String uploadUrl,
    Map<String, dynamic>? formData,
  }) async {
    try {
      // 获取MIME类型
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final contentType = MediaType.parse(mimeType);

      // 创建FormData
      final formDataToSend = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: contentType,
        ),
        ...?formData, // 添加额外的表单数据
      });

      // 发送请求
      final response = await dio.post(
        uploadUrl,
        data: formDataToSend,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return ResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('文件上传失败: ${e.message}');
    } catch (e) {
      throw Exception('文件上传失败: $e');
    }
  }

  /// 专门用于上传文档的方法
  /// [filePath] 文件路径
  /// [fileName] 文件名
  /// [tenantId] 租户ID
  /// [directoryId] 目录ID
  Future<ResponseModel> uploadDoc({
    required String filePath,
    required String fileName,
    required String tenantId,
    required String directoryId,
  }) async {
    return await uploadFile(
      filePath: filePath,
      fileName: fileName,
      uploadUrl: '/service/ai/uploadDoc/$tenantId/$directoryId',
    );
  }
}

Dio dio = HttpUtil.getInstance().dio;