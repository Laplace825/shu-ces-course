/*
 * @Author: Laplace
 * @Date: 2024-03-23 16:57:04
 * @LastEditors: laplace825
 * @LastEditTime: 2024-04-30 22:12:11
 * @FilePath: /ds2/Vigenere/vigenere.hpp
 * Copyright (c) 2024 by Laplace, All Rights Reserved.
 */
#pragma once
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <initializer_list>
#include <opencv2/opencv.hpp>
#include <string>
#include <tuple>
#include <vector>

namespace Vige {

// 定义 VigenereCipher 类，用于实现 Vigenere 密码机加密算法
class VigenereCipher {
   private:
    std::string m_key;

   public:
    explicit VigenereCipher(const std::string &key) : m_key(key) {
        std::transform(m_key.begin(), m_key.end(), m_key.begin(),
                       ::tolower);  // 转换为小写
    }

    // 使用 Caesar 加密算法对字符串进行加密
    // 参数 plainText: 要加密的明文字符串
    // 返回加密后的密文字符串
    std::string encrypt(const std::string &plainText) {
        std::string cipherText;  // 用于存储加密后的字符串
        int keyIndex = 0;        // 密钥索引
        for (char c : plainText) {
            if (isalpha(c))  // 判断字符是否为字母
            {
                int keyValue = m_key[keyIndex] - 'a';  // 计算密钥值
                int plainValue =
                    (isupper(c) ? c - 'A' : c - 'a');  // 计算明文值
                int cipherValue = (plainValue + keyValue) % 26;  // 计算密文值
                cipherText.push_back(isupper(c)
                                         ? cipherValue + 'A'
                                         : cipherValue + 'a');  // 拼接密文字符
                /**
                 * @note:
                 * 相当于将密钥字符串循环到与明文字符串等长，然后再将明文字符加密
                 */
                keyIndex = (keyIndex + 1) % m_key.length();  // 更新密钥索引
            } else {
                cipherText.push_back(c);  // 非字母字符直接添加到密文中
            }
        }
        std::for_each(cipherText.begin(), cipherText.end(), [](char &c) {
            if (isalpha(c)) c = std::tolower(c);
        });                 // 转换为小写
        return cipherText;  // 返回加密后的密文字符串
    }

    // 函数用途：解密密文
    // 参数：cipherText - 待解密的密文
    // 返回值：解密后的明文
    std::string decrypt(const std::string &cipherText) noexcept {
        // 存储解密后的明文
        std::string plainText;
        // 密钥索引
        int keyIndex = 0;
        for (char c : cipherText) {
            if (isalpha(c)) {
                // 计算密文字符对应的明文字符值
                int keyValue = m_key[keyIndex] - 'a';
                int cipherValue = (isupper(c) ? c - 'A' : c - 'a');
                // 由于密文字符可能大于明文字符，所以需要将密文字符减去密钥值，然后再加
                // 26 取模，得到明文字符值
                int plainValue = (cipherValue - keyValue + 26) % 26;
                plainText.push_back(isupper(c) ? plainValue + 'A'
                                               : plainValue + 'a');
                // 更新密钥索引
                keyIndex = (keyIndex + 1) % m_key.length();
            } else {
                // 非字母字符直接追加到明文中
                plainText.push_back(c);
            }
        }
        // 返回解密后的明文
        return plainText;
    }
};

/**
 * @description: Friedman 指数测试,得到密文的 Friedman
 * 指数即密文的重合指数和长度估计
 * @param {string} &cipherText
 * @return {*}
 */
auto FriedmanTest(const std::string &cipherText) {
    using ll = long long;

    std::vector<double> frequency(26, 0);  // 存储密文字符的频率
    for (char c : cipherText) {
        if (isalpha(c)) {
            frequency[std::tolower(c) - 'a']++;  // 统计密文字符的频
        }
    }
    double sum = 0.;  // 计算密文中所有字母的总数
    for (ll f : frequency) {
        sum += f;
    }
    double k0 = 0.0;  // 计算 Friedman 指数
    for (ll f : frequency) {
        k0 += f * (f - 1);
    }
    if (sum != 1) k0 /= sum * (sum - 1);
    double estimate_length = (0.067 - 0.0385) / (k0 - 0.0385);

    return std::make_tuple(k0, std::ceil(estimate_length));
}

auto get_key(const std::string &cipherText, int length) {
    /**
     * @description: 根據FriedmanTest函數
     * 得到的密文的 Friedman 指数和长度估计，得到密鑰
     * @param {string} &cipherText
     * @return {*}
     */
    auto textToList = [](const std::string &text, int length) {
        std::vector<std::string> matrix;
        matrix.clear();
        std::string row;
        size_t index = 0;
        for (auto ch : text) {
            if (isalpha(ch)) {
                row.push_back(ch);
                index++;
                if (index % length == 0) {
                    matrix.push_back(row);
                    row.clear();
                }
            }
        }
        return matrix;
    };

    auto countList = [](const std::string &text) {
        std::vector<double> li(26, 0);
        size_t len = 0;
        for (char c : text) {
            if (isalpha(c)) {
                len++;
                li[std::tolower(c) - 'a']++;
            }
        }
        for (double &i : li) {
            i /= len;
        }
        return li;
    };

    std::string key;
    std::vector<double> alphaRate = {
        0.08167, 0.01492, 0.02782, 0.04253, 0.12705, 0.02228, 0.02015,
        0.06094, 0.06996, 0.00153, 0.00772, 0.04025, 0.02406, 0.06749,
        0.07507, 0.01929, 0.0009,  0.05987, 0.06327, 0.09056, 0.02758,
        0.00978, 0.02360, 0.0015,  0.01974, 0.00074};
    std::vector<std::string> matrix = textToList(cipherText, length);

    for (int i = 0; i < length; ++i) {
        std::string w;
        for (const std::string &row : matrix) {
            w.push_back(row[i]);
        }
        std::vector<double> li = countList(w);
        std::vector<double> powLi;
        for (int j = 0; j < 26; ++j) {
            double Sum = 0.0;
            for (int k = 0; k < 26; ++k) {
                Sum += alphaRate[k] * li[k];
            }
            powLi.push_back(Sum);
            std::rotate(li.begin(), li.begin() + 1, li.end());
        }
        double Abs = 100;
        char ch = ' ';
        for (int j = 0; j < powLi.size(); ++j) {
            if (std::abs(powLi[j] - 0.065546) < Abs) {
                Abs = std::abs(powLi[j] - 0.065546);
                ch = char(j + 97);
            }
        }
        key.push_back(ch);
    }

    return key;
}

// 基于vigenere加密算法的 opencv 图像加密

class VigenereImg {
   private:
    std::vector<u_char> m_key;  // char 恰好为一个字节

    // 获取当前工作路径
    std::string workingPath() const {
        return std::filesystem::path(__FILE__).parent_path().string();
    }

   public:
    explicit VigenereImg(const std::vector<u_char> &key) : m_key(key) {}

    // 使用 Caesar 加密算法对字符串进行加密
    // 参数 plainText: 要加密的明文字符串
    // 返回加密后的密文字符串
    cv::Mat encrypt(const cv::Mat &src) {
        cv::Mat dst = src.clone();
        int keyIndex = 0;  // 密钥索引
        for (size_t i = 0; i < src.rows; i++) {
            for (size_t j = 0; j < src.cols; j++) {
                cv::Vec3b pixel = src.at<cv::Vec3b>(i, j);  // 获取像素值
                for (int k = 0; k < 3; k++) {
                    u_char keyValue = m_key[keyIndex];  // 计算密钥值
                    u_char plainValue = pixel.val[k];   // 计算明文值
                    u_char cipherValue =
                        (plainValue + keyValue + 128) % 256;  // 计算密文值
                    pixel.val[k] = cipherValue;  // 拼接密文字符
                    keyIndex = (keyIndex + 1) % m_key.size();  // 更新密钥索引
                }
                dst.at<cv::Vec3b>(i, j) = pixel;
            }
        }
        return dst;  // 返回加密后的密文字符串
    }

    // 函数用途：解密密文
    // 参数：cipherText - 待解密的密文
    // 返回值：解密后的明文
    cv::Mat decrypt(const cv::Mat &src) noexcept {
        cv::Mat dst = src.clone();
        int keyIndex = 0;  // 密钥索引
        for (int i = 0; i < src.rows; i++) {
            for (int j = 0; j < src.cols; j++) {
                cv::Vec3b pixel = src.at<cv::Vec3b>(i, j);
                for (int k = 0; k < 3; k++) {
                    int keyValue = m_key[keyIndex];  // 计算密钥值
                    int cipherValue = pixel[k];      // 计算密文值
                    int plainValue = (cipherValue - keyValue + 256 - 128) %
                                     256;   // 计算明文值
                    pixel[k] = plainValue;  // 拼接密文字符
                    keyIndex = (keyIndex + 1) % m_key.size();  // 更新密钥索引
                }
                dst.at<cv::Vec3b>(i, j) = pixel;
            }
        }
        return dst;  // 返回加密后的密文字符串
    }
};

}  // namespace Vige