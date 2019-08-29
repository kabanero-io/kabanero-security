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

public class Constants {

    public static final String GITHUB_API_URL_BASE = "https://api.github.com";
    public static final String GITHUB_URL_MPCONFIG_PROPERTYNAME = "github.api.url";

    public static final String LOGIN_KEY_GITHUB_USER = "gituser";
    public static final String LOGIN_KEY_GITHUB_PASSWORD_OR_PAT = "gitpat";
    public static final String PAT_JWT_CLAIM = "pat";
    public static final String ROLESPREFIXOLD = "groupsForTeam_";
    public static final String ROLESPREFIX = "teamsInGroup_";
    public static final String ENVIRONMENT_VARIABLE_NAME_ALLOWED_CHARS="ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789";
 }
