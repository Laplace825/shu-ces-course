/*
 * @Author: Laplace
 * @Date: 2024-03-23 16:41:01
 * @LastEditors: laplace825
 * @LastEditTime: 2024-04-30 22:11:10
 * @FilePath: /ds2/Vigenere/vigenere.cpp
 * Copyright (c) 2024 by Laplace, All Rights Reserved.
 */
#include "vigenere.hpp"

#include <algorithm>
#include <cstring>
#include <format>
#include <fstream>
#include <iostream>
#include <opencv2/opencv.hpp>
#include <string>
#include <vector>

auto read_file(const char *filename) {
    /**
     * Read the lines of a file into a vector of strings, and split each word
     * into a vector of characters.
     * @param filename The name of the file to read.
     * @return A vector of strings containing every words of the file.
     */
    std::ifstream file;
    file.open(filename);
    if (!file.is_open()) {
        std::cerr << "Unable to open file: " << filename << '\n';
        exit(1);
    }
    std::string word;
    std::vector< std::string > words;
    while (std::getline(file, word)) {
        words.push_back(word);
    }
    word.clear();
    for (const auto &w : words) {
        word.append(w);
    }
    file.close();
    return word;
}

auto write_file(
  const char *filename, const std::string &words, bool append = false) {
    /**
     * Write a vector of strings to a file, with each string on a new line.
     * @param filename The name of the file to write to.
     * @param words The vector of strings to write to the file.
     */
    std::ofstream file;
    if (!append)
        file.open(filename);
    else
        file.open(filename, std::ios::app);
    file << words;
    file.close();
}

std::string getTextCipher(
  const std::string &plainText, const std::string &key) {
    Vige::VigenereCipher cipher(key);

    std::string cipherText = cipher.encrypt(plainText);

    return cipherText;
}

std::string getTextPlain(
  const std::string &cipherText, const std::string &key) {
    Vige::VigenereCipher cipher(key);

    std::string plainText = cipher.decrypt(cipherText);

    return plainText;
}

cv::Mat getImgCipher(
  const cv::Mat &plainImg, const std::vector< u_char > &key) {
    Vige::VigenereImg cipher(key);

    auto cipherImg = cipher.encrypt(plainImg);

    return cipherImg;
}

cv::Mat getImgPlain(
  const cv::Mat &cipherImg, const std::vector< u_char > &key) {
    Vige::VigenereImg cipher(key);

    auto plainImg = cipher.decrypt(cipherImg);

    return plainImg;
}

void help() {
    std::cout << "\033[1;32mUsage: ./vegenere [plain path] [key text "
                 "path] [pattern] [output file]\033[0m\n";
    std::cout << "\033[1;33m[text]\033[0mExample: ./vegenere plain.txt "
                 "./key.txt -ot ./output.txt\n";
    std::cout << "\033[1;33m[image]\033[0mExample: ./vegenere plain.jpg "
                 "./key.txt -ope ./output.jpg\n";
    std::cout << "\033[1;33m[image]\033[0mExample: ./vegenere plain.jpg "
                 "./key.txt -opd ./output.jpg\n";
    std::cout << "The Cipher text will be saved in the file named "
                 "'vigenere_ciphertext.txt' in the same directory with the "
                 "execuable file.\n";
}

int main(int argc, char const *argv[]) {
    if (argc == 1) {
        help();
        return -1;
    }
    else if (strcmp(argv[1], "help") == 0 || strcmp(argv[1], "-h") == 0 ||
             strcmp(argv[1], "--help") == 0)
    {
        help();
        return 0;
    }
    else if (argc != 5) {
        std::cout << "\033[1;31mError: Invalid arguments.\033[0m\n";
        help();
        return -1;
    }

    const std::string pattern = argv[3];

    if (pattern == "-ot") {
        /**
         * @note: argv[1] 存放明文字符串文件名，argv[2] 存放密钥字符串文件名
         */
        std::string plainText  = read_file(argv[1]);
        std::string key        = read_file(argv[2]);
        const char *outputFile = argv[4];
        // std::string plainText = read_file("../poem.txt");
        // std::string key = read_file("../vigenere_key.txt");
        auto cipher = getTextCipher(plainText, key);
        write_file("./vigenere_ciphertext.txt", cipher);

        auto [index, keyLength] =
          Vige::FriedmanTest(read_file("./vigenere_ciphertext.txt"));
        // 输出密钥长度
        auto cipherText = read_file("./vigenere_ciphertext.txt");
        std::cout << std::format(
          "k_0 : {}\nestimated Key length: {}\n", index, keyLength);

        // 通过密钥解密原文写入文件
        auto AfterPlainText = getTextPlain(cipherText, key);
        write_file(
          outputFile, std::format(">>>>>>[encrypt]\n{}\n<<<<<<\n", cipher));

        write_file(outputFile,
          std::format("\n>>>>>>>[decrypt]\n{}\n<<<<<<\n", AfterPlainText),
          true);

        // 输出估计的密钥
        auto keyEstimate = Vige::get_key(cipherText, keyLength);
        std::cout << "Key: " << keyEstimate << std::endl;
    }
    else if (pattern == "-ope") {
        /**
         * @note: argv[1] 存放明文图片文件名，argv[2] 存放密钥字符串文件名
         */

        cv::Mat plainImg = cv::imread(argv[1], cv::IMREAD_COLOR);
        std::ifstream file(argv[2]);
        if (file.fail()) {
            std::cerr << "Error: Unable to open file: " << argv[1] << '\n';
            return -1;
        }
        else {
            std::vector< u_char > key;
            std::string tmp;
            while (std::getline(file, tmp)) {
                tmp.erase(std::remove(tmp.begin(), tmp.end(), ' '), tmp.end());
                key.push_back(std::stoi(tmp));
            }

            cv::Mat cipherImg = getImgCipher(plainImg, key);
            cv::imwrite(argv[4], cipherImg);
            std::cout << "The cipher image has been saved as \033[1;32m"
                      << argv[4] << "\033[0m\n";
        }
    }
    else if (pattern == "-opd") {
        /**
         * @note: argv[1] 存放密文图片文件名，argv[2] 存放密钥字符串文件名
         */
        cv::Mat cipherImg = cv::imread(argv[1], cv::IMREAD_COLOR);
        // 读取密钥文件
        std::ifstream file(argv[2]);
        if (file.fail()) {
            std::cerr << "Error: Unable to open file: " << argv[2] << '\n';
            return -1;
        }
        else {
            std::vector< u_char > key;
            std::string tmp;
            while (std::getline(file, tmp)) {
                tmp.erase(std::remove(tmp.begin(), tmp.end(), ' '), tmp.end());
                key.push_back(std::stoi(tmp));
            }
            cv::Mat plainImg = getImgPlain(cipherImg, key);
            cv::imwrite(argv[4], plainImg);
            std::cout << "The plain image has been saved as \033[1;32m"
                      << argv[4] << "\033[0m\n";
        }
    }
    else {
        std::cout << "\033[1;31mError: Invalid arguments.\033[0m\n";
        help();
        return -1;
    }

    return 0;
}