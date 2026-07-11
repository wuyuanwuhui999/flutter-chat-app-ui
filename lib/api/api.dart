const servicePath = {
  'login': '/service/user/login', //登录
  'getUserData': '/service/user/getUserData', // 获取用户信息
  'updateUser': '/service/user/updateUser',//更新用户信息
  'register': '/service/user/register',//注册
  'vertifyUser': '/service/user/vertifyUser',// 校验账号是否存在
  'sendEmailVertifyCode': '/service/user/sendEmailVertifyCode',// 找回密码
  'resetPassword': '/service/user/resetPassword',// 重置密码
  'updateAvater':'/service/user/updateAvater',//更新头像
  'updatePassword': '/service/user/updatePassword',//更新密码
  'loginByEmail': '/service/user/loginByEmail',//邮箱登录
  'chat':"/service/chat/chat",// ai聊天
  'getChatHistory': "/service/chat/getChatHistory",// ai聊天
  'chatWs': "/service/chat/ws/chat",// ai聊天
  'getModelList': "/service/chat/getModelList",// ai聊天
  'getDocList': "/service/chat/getDocList",// 查询我的文档
  'deleteDoc': "/service/chat/deleteDoc/",// 查询我的文档
  'getDirectoryList':"/service/chat/getDirectoryList",// 按照租户查询文档目录列表
  'createDir': "/service/chat/createDir",// 创建目录
  'getTenantList': "/service/tenant/getTenantList",// 获取用户的所有租户
  'getTenantUserList': "/service/tenant/getTenantUserList",// 获取当前租户下的所有租户
  'addAdmin': "/service/tenant/addAdmin",// 给用户添加管理员
  'cancelAdmin': "/service/tenant/cancelAdmin",// 删除管理员
  'searchUsers': "/service/user/searchUsers",// 搜索用户
  'addTenantUser': "/service/tenant/addTenantUser",// 添加租户用户
  'deleteTenantUser': "/service/tenant/deleteTenantUser",// 删除租户用户
  'getCompanyList': "/service/company/getCompanyList" // 获取公司列表
};
