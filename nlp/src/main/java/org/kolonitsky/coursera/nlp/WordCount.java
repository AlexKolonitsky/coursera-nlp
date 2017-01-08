package org.kolonitsky.coursera.nlp;


import org.apache.commons.lang3.StringUtils;

/**
 * @author Alex.Kolonitsky
 */
public class WordCount {
    public final int count;
    public final String words[];

    public WordCount(int count, String ... words) {
        this.words = words;
        this.count = count;
    }

    public String getText() {
        return StringUtils.join(words, " ");
    }

    @Override
    public String toString() {
        return count + StringUtils.join(words, " ");
    }
}
