/*
 * Copyright (c) 2019 IBM Corporation and others
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package kabasec;

import javax.servlet.http.HttpServletResponse;

public class KabaneroSecurityException extends Exception {

    private static final long serialVersionUID = 1L;

    private int statusCode = HttpServletResponse.SC_INTERNAL_SERVER_ERROR;

    public KabaneroSecurityException(int statusCode, String message) {
        super(message);
        this.statusCode = statusCode;
    }

    public KabaneroSecurityException(String message, Throwable cause) {
        super(message, cause);
        if (cause instanceof KabaneroSecurityException) {
            this.statusCode = ((KabaneroSecurityException) cause).getStatusCode();
        }
    }

    int getStatusCode() {
        return statusCode;
    }

}
