import 'dart:developer';
import 'package:dio/dio.dart';

enum SWRequestMethod {
  get,
  post
}

enum SWRequestSerializerType {
  json,
  http
}

enum SWResponseSerializerType {
  json,
  string,
  byte
}

abstract class SWRequest {
  SWRequestMethod requestMethod() {
    return SWRequestMethod.get;
  }

  SWRequestSerializerType requestSerializerType() {
    return SWRequestSerializerType.json;
  }

  SWResponseSerializerType responseSerializerType() {
    return SWResponseSerializerType.json;
  }

  String? baseUrl() {
    return null;
  }

  String requestUrl() {
    return "";
  }

  Map<String,dynamic>? requestHeader() {
    return null;
  }

  Map<String,dynamic>? requestArgument() {
    return null;
  }
  /*超时时间,单位秒*/
  int sendTimeoutInterval() {
    return 30;
  }
/*根据服务器响应状态码,决定是否请求成功.返回`true` , 请求结果就会按成功处理，否则会按失败处理*/
  bool determineHttpStatus(int? httpResponseCode) {
    return httpResponseCode == 200;
  }

  Future<Response?> startRequest() async {
    var dio = Dio();
    Response? response = null;
    var url = (baseUrl() ?? "") + requestUrl();
    var option = Options(responseType: ResponseType.json,headers: requestHeader(),contentType: requestSerializerType() == SWRequestSerializerType.json ? Headers.jsonContentType : Headers.formUrlEncodedContentType,sendTimeout: sendTimeoutInterval()*1000,validateStatus:(code){
      return determineHttpStatus(code);
    });
    if(responseSerializerType() == SWResponseSerializerType.string) {
      option.responseType = ResponseType.plain;
    }
    else if(responseSerializerType() == SWResponseSerializerType.byte) {
      option.responseType = ResponseType.bytes;
    }
    DioError? dioError = null;
    try {
      if(requestMethod() == SWRequestMethod.get) {
        option.responseType = ResponseType.plain;
        response = await dio.get(url,queryParameters: requestArgument(),options: option);
      }
      else if(requestMethod() == SWRequestMethod.post) {
        response = await dio.post(url,queryParameters: requestArgument(),options: option);
      }
      return response;
    } on DioError catch(error) {
      dioError = error;
      response = error.response;
      return Future.error(error);
    }finally {
      log("\n----------------------------------------begin----------------------------------------\n请求方法:${requestMethod() == SWRequestMethod.get ? "GET" : "POST"}\n请求地址:$url\n请求头:${response?.requestOptions.headers}\n请求参数:${requestArgument()}\n请求状态:${dioError != null ? "失败\n错误信息:${dioError.error}" : "成功"}\n响应头:${response?.headers.map}\nstatusCode:${response?.statusCode}\nstatusMessage:${response?.statusMessage}\n响应体:${response?.data}\n----------------------------------------end----------------------------------------");
    }

  }
}