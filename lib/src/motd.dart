// Copyright (C) 2022 Zxbase, LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Message of the day.

class MOTD {
  MOTD(
      {required this.id,
      required this.message,
      required this.notes,
      required this.date});

  MOTD.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    message = parsedJson['message'];
    notes = parsedJson['notes'];
    date = DateTime.parse(parsedJson['date']);
  }

  late int id;
  late String message;
  late String notes;
  late DateTime date;
}
