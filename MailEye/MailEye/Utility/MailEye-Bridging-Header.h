//
// Copyright (c) 2018 ANONYMISED
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// MARK: - Not standard lib

#include <curl/curl.h>
#import "lsl_c.h"

// MARK: - Standard lib includes

#import <CommonCrypto/CommonDigest.h>

typedef size_t (*curl_func)(void * ptr, size_t size, size_t num, void * ud);

// contains static functions to map to predefined c functions,
// since variadic functions are invalid in swift

static CURLcode curl_easy_setopt_cstr(CURL *handle, CURLoption option, const char * value)
{
    return curl_easy_setopt(handle, option, value);
}

static CURLcode curl_easy_setopt_long(CURL *handle, CURLoption option, const long value)
{
    return curl_easy_setopt(handle, option, value);
}

static CURLcode curl_easy_setopt_ptr(CURL *handle, CURLoption option, void * value)
{
    return curl_easy_setopt(handle, option, value);
}

static CURLcode curl_easy_setopt_func(CURL *handle, CURLoption option, curl_func value)
{
    return curl_easy_setopt(handle, option, value);
}

