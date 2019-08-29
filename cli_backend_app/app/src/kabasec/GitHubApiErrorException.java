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

import java.io.StringReader;

import javax.json.Json;
import javax.json.JsonObject;

public class GitHubApiErrorException extends KabaneroSecurityException {

    private static final long serialVersionUID = 1L;

    public GitHubApiErrorException(int statusCode, String githubResponse, String message) {
        super(statusCode, createMessageFromGitHubResponse(githubResponse, message));
    }

    private static String createMessageFromGitHubResponse(String githubResponse, String message) {
        String newMessage = message;
        try {
            JsonObject responseJson = Json.createReader(new StringReader(githubResponse)).readObject();
            String ghMessage = responseJson.getString("message");
            newMessage += " The response message from GitHub was \"" + ghMessage + "\".";
            String documentationUrl = responseJson.getString("documentation_url");
            if (documentationUrl != null && !documentationUrl.isEmpty()) {
                newMessage += " See the documentation for this API at " + documentationUrl + ".";
            }
        } catch (Exception e) {
            // Expected the response to be a JSON object but failed to parse or process the string
            newMessage = "Caught exception extracting an error message from the GitHub response [" + githubResponse + "]. Exception was: " + e;
            e.printStackTrace();
        }
        return newMessage;
    }

}
