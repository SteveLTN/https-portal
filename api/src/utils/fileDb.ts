import fs from "fs";
import path from "path";

export class PlainTextFileDb {
  private filepath: string;

  constructor(filepath: string) {
    this.filepath = filepath;
  }

  read(): string | undefined {
    try {
      return fs.readFileSync(this.filepath, "utf8").trim();
    } catch (e) {
      if (e.code !== "ENOENT") throw e;
    }
  }

  write(data: string): void {
    fs.mkdirSync(path.dirname(this.filepath), { recursive: true });
    fs.writeFileSync(this.filepath, data);
  }

  del(): void {
    try {
      fs.unlinkSync(this.filepath);
    } catch (e) {
      if (e.code !== "ENOENT") throw e;
    }
  }
}

export class JsonFileDb<T> {
  private fileDb: PlainTextFileDb;
  private defaultValue: T;

  constructor(filepath: string, defaultValue: T) {
    this.fileDb = new PlainTextFileDb(filepath);
    this.defaultValue = defaultValue;
  }

  read(): T {
    const data = this.fileDb.read();
    if (data) return JSON.parse(data);
    else return this.defaultValue;
  }

  write(data: T): void {
    this.fileDb.write(JSON.stringify(data, null, 2));
  }

  del(): void {
    this.fileDb.del();
  }
}
