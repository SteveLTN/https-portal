import { DomainMapping } from "./types";
import { config } from "./config";
import { JsonFileDb } from "./utils/fileDb";

export const entriesDb = new JsonFileDb<DomainMapping[]>(
  config.db_filepath,
  []
);
