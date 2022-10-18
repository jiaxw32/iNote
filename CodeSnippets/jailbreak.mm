__int64 sub_6E0B00()
{
  void *v0; // x0
  __int64 v1; // x19
  void *v2; // x0
  __int64 v3; // x20
  void *v4; // x0
  void *v5; // x23
  int v6; // w24
  void *v7; // x0
  void *v8; // x21
  int v9; // w22

  v0 = objc_msgSend(
         &OBJC_CLASS___NSString,
         "stringWithFormat:",
         CFSTR("/%@/%@%@%@.%@"),
         CFSTR("Applications"),
         CFSTR("Cy"),
         CFSTR("di"),
         CFSTR("a"),
         CFSTR("app"));
  v1 = objc_retainAutoreleasedReturnValue(v0);
  v2 = objc_msgSend(
         &OBJC_CLASS___NSString,
         "stringWithFormat:",
         CFSTR("/%@/%@/%@/%@/"),
         CFSTR("private"),
         CFSTR("var"),
         CFSTR("lib"),
         CFSTR("apt"));
  v3 = objc_retainAutoreleasedReturnValue(v2);
  v4 = objc_msgSend(&OBJC_CLASS___NSFileManager, "defaultManager");
  v5 = (void *)objc_retainAutoreleasedReturnValue(v4);
  v6 = (unsigned __int64)objc_msgSend(v5, "fileExistsAtPath:", v1);
  objc_release(v5);
  if ( v6 )
    byte_11E7FF0 = 1;
  v7 = objc_msgSend(&OBJC_CLASS___NSFileManager, "defaultManager");
  v8 = (void *)objc_retainAutoreleasedReturnValue(v7);
  v9 = (unsigned __int64)objc_msgSend(v8, "fileExistsAtPath:", v3);
  objc_release(v8);
  if ( v9 )
    byte_11E7FF0 = 1;
  objc_release(v3);
  return objc_release(v1);
}

bool __cdecl -[UIDevice isJailBreak](UIDevice *self, SEL a2)
{
  void *v2; // x0
  void *v3; // x19
  void *v4; // x0
  __int64 v5; // x21
  char v6; // w20
  void *v7; // x0
  void *v8; // x19
  char v9; // w22
  __int64 v11; // x26
  void *v12; // x0
  void *v13; // x19
  void *v14; // x0
  __int64 v15; // x23
  char v16; // w24

  v2 = objc_msgSend(&OBJC_CLASS___UIApplication, "sharedApplication");
  v3 = (void *)objc_retainAutoreleasedReturnValue(v2);
  v4 = objc_msgSend(&OBJC_CLASS___NSURL, "URLWithString:", CFSTR("cydia://"));
  v5 = objc_retainAutoreleasedReturnValue(v4);
  v6 = (unsigned __int64)objc_msgSend(v3, "canOpenURL:", v5);
  objc_release(v5);
  objc_release(v3);
  if ( !(v6 & 1) )
  {
    v7 = objc_msgSend(&OBJC_CLASS___NSFileManager, "defaultManager");
    v8 = (void *)objc_retainAutoreleasedReturnValue(v7);
    v9 = (unsigned __int64)objc_msgSend(v8, "fileExistsAtPath:", CFSTR("/User/Applications/"));
    objc_release(v8);
    if ( !(v9 & 1) )
    {
      v11 = 0LL;
      while ( 1 )
      {
        v12 = objc_msgSend(&OBJC_CLASS___NSFileManager, "defaultManager");
        v13 = (void *)objc_retainAutoreleasedReturnValue(v12);
        v14 = objc_msgSend(&OBJC_CLASS___NSString, "stringWithUTF8String:", off_10D259C08[v11]);
        v15 = objc_retainAutoreleasedReturnValue(v14);
        v16 = (unsigned __int64)objc_msgSend(v13, "fileExistsAtPath:", v15);
        objc_release(v15);
        objc_release(v13);
        if ( v16 & 1 )
          break;
        ++v11;
        if ( v11 == 5 )
          return 0;
      }
    }
  }
  return 1;
}
