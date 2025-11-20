#!/bin/bash

# 设置 BAM 文件所在目录和输出目录
BAM_DIR="/data/liyaowen/software/cnvOffSeq-master/1kgp_exome_bam"  # BAM 文件目录
OUTPUT_DIR="/data/liyaowen/software/cnvOffSeq-master/chr6-bam"      # 输出目录
CHROM="chr6"  # 需要提取的染色体

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

# 遍历 BAM 文件目录中的每个 BAM 文件
for BAM_FILE in "$BAM_DIR"/*.bam; do
    BASE_NAME=$(basename "$BAM_FILE" .bam)
    OUTPUT_BAM="$OUTPUT_DIR/${BASE_NAME}_${CHROM}.bam"

    echo "正在处理 $BAM_FILE，提取染色体 $CHROM..."
    
    # 调用提取脚本生成 BAM
    sh /data/liyaowen/software/cnvOffSeq-master/extract_region_from_BAM.sh "$BAM_FILE" "$OUTPUT_BAM" "$CHROM"

    # 生成对应的 BAI 索引
    samtools index "$OUTPUT_BAM"
    echo "✅ 已生成 BAM 和索引: $OUTPUT_BAM 和 ${OUTPUT_BAM}.bai"
done

echo "所有 BAM 文件提取完成，索引已生成。"
